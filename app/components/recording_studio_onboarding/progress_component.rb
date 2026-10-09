# frozen_string_literal: true

module RecordingStudioOnboarding
  # Flow progress: Flatpack Progress (bar) or segment trail (labels above the line).
  class ProgressComponent < ViewComponent::Base
    def initialize(run:, mode: nil)
      super()
      @run = run
      @mode = (mode || run.definition&.progress || :segments).to_sym
    end

    def render?
      visible_steps.any?
    end

    def call
      content_tag(:div, class: "w-full", data: { testid: "onboarding-progress", mode: @mode }) do
        @mode == :bar ? render_bar : render_segments
      end
    end

    private

    def visible_steps
      @visible_steps ||= @run.definition&.visible_steps || []
    end

    def current_index
      keys = visible_steps.map(&:key)
      index = keys.index(@run.current_step_key.to_sym)
      return index if index

      keys.each_with_index do |key, i|
        return i unless step_done?(key)
      end
      keys.size
    end

    def render_bar
      done = visible_steps.count { |step| step_done?(step.key) }
      render FlatPack::Progress::Component.new(
        value: done,
        max: visible_steps.size,
        show_label: true,
        label: "#{done} of #{visible_steps.size}",
        size: :md
      )
    end

    def render_segments
      SegmentsTrail.new(
        steps: visible_steps,
        current_step: [current_index + 1, 1].max,
        view_context: self
      ).call
    end

    def step_done?(key)
      progress = @run.step_progresses.find { |row| row.step_key == key.to_s }
      progress && %w[completed skipped].include?(progress.status)
    end

    # Horizontal trail: labels above markers so the connector never cuts text.
    # Flatpack Stepper places labels beside markers (through the line), so this
    # trail uses Flatpack stepper tokens + IconComponent instead.
    class SegmentsTrail
      MARKER_TONES = {
        complete: "border-[var(--stepper-complete-color)] bg-[var(--stepper-complete-color)] " \
                  "text-[var(--stepper-complete-text-color)]",
        current: "border-[var(--stepper-current-color)] bg-[var(--stepper-current-color)] " \
                 "text-[var(--surface-page-background-color)]",
        upcoming: "border-[var(--stepper-upcoming-color)] bg-[var(--surface-page-background-color)] " \
                  "text-[var(--stepper-muted-color)]"
      }.freeze

      def initialize(steps:, current_step:, view_context:)
        @steps = steps
        @current_step = current_step
        @view = view_context
      end

      def call
        @view.content_tag(:ol, class: "flex w-full items-start", aria: { label: "Progress" }) do
          @view.safe_join(@steps.each_with_index.map { |step, index| item(step, index) })
        end
      end

      private

      def item(step, index)
        number = index + 1
        status = status_for(number)
        @view.content_tag(
          :li,
          class: "relative flex min-w-0 flex-1 flex-col items-center",
          data: { status: status }
        ) do
          @view.safe_join([label(step, status), track(number, status, index)])
        end
      end

      def status_for(number)
        if number < @current_step
          :complete
        elsif number == @current_step
          :current
        else
          :upcoming
        end
      end

      def label(step, status)
        current = status == :current
        classes = label_classes(current)
        @view.content_tag(
          :p,
          step.key.to_s.humanize,
          class: classes,
          aria: (current ? { current: "step" } : {})
        )
      end

      def label_classes(current)
        tone = current ? "text-[var(--stepper-label-color)]" : "text-[var(--stepper-muted-color)]"
        "relative z-10 mb-2 w-full px-1 text-center text-sm font-medium #{tone}"
      end

      def track(number, status, index)
        @view.content_tag(:div, class: "relative flex h-8 w-full items-center justify-center") do
          @view.safe_join(
            [
              (connector(:left) unless index.zero?),
              marker(number, status),
              (connector(:right) unless index == @steps.size - 1)
            ].compact
          )
        end
      end

      def connector(side)
        position = side == :left ? "left-0 right-1/2" : "left-1/2 right-0"
        @view.content_tag(
          :span,
          nil,
          class: "pointer-events-none absolute #{position} top-1/2 h-px -translate-y-1/2 " \
                 "bg-[var(--stepper-upcoming-color)]",
          "aria-hidden": "true"
        )
      end

      def marker(number, status)
        @view.content_tag(:span, class: marker_classes(status), aria: { hidden: "true" }) do
          if status == :complete
            @view.render FlatPack::Shared::IconComponent.new(name: "check", size: :sm)
          else
            @view.content_tag(:span, number.to_s, class: "fp-tabular-nums text-xs font-semibold")
          end
        end
      end

      def marker_classes(status)
        base = "relative z-10 flex h-8 w-8 shrink-0 items-center justify-center rounded-full border"
        "#{base} #{MARKER_TONES.fetch(status)}"
      end
    end
  end
end
