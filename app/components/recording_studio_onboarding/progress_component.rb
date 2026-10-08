# frozen_string_literal: true

module RecordingStudioOnboarding
  # Flow progress using Flatpack Progress (bar) or Stepper (segments).
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
        if @mode == :bar
          render_bar
        else
          render_segments
        end
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

      # Hidden current step (show_progress: false): point at first incomplete visible step.
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
      render FlatPack::Stepper::Component.new(
        current_step: [current_index + 1, 1].max,
        orientation: :horizontal,
        steps: visible_steps.map { |step| { label: step.key.to_s.humanize } }
      )
    end

    def step_done?(key)
      progress = @run.step_progresses.find { |row| row.step_key == key.to_s }
      progress && %w[completed skipped].include?(progress.status)
    end
  end
end
