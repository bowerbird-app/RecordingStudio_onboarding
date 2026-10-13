# frozen_string_literal: true

module RecordingStudioOnboarding
  # Flow progress as a line (Flatpack Progress). Numbered segment headers are gone.
  # Value is the 1-based current step so step 1 already shows colored progress.
  class ProgressComponent < ViewComponent::Base
    def initialize(run:, mode: nil)
      super()
      @run = run
      @mode = :bar
      _ = mode # accepted for call-site compatibility; always bar
    end

    def render?
      visible_steps.any?
    end

    def call
      content_tag(:div, class: "w-full", data: { testid: "onboarding-progress", mode: @mode }) do
        render_bar
      end
    end

    private

    def visible_steps
      @visible_steps ||= @run.definition&.visible_steps || []
    end

    def current_step_number
      keys = visible_steps.map(&:key)
      index = keys.index(@run.current_step_key.to_sym)
      return index + 1 if index

      keys.each_with_index do |key, i|
        return i + 1 unless step_done?(key)
      end
      [keys.size, 1].max
    end

    def render_bar
      current = current_step_number
      total = visible_steps.size
      render FlatPack::Progress::Component.new(
        value: current,
        max: total,
        show_label: false,
        label_visible: false,
        label: "Step #{current} of #{total}",
        size: :md
      )
    end

    def step_done?(key)
      progress = @run.step_progresses.find { |row| row.step_key == key.to_s }
      progress && %w[completed skipped].include?(progress.status)
    end
  end
end
