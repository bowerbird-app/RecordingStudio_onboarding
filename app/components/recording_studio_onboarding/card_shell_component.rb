# frozen_string_literal: true

module RecordingStudioOnboarding
  # Minimal outer presentation: centres the card, Flatpack theme, flexible dimensions.
  class CardShellComponent < ViewComponent::Base
    def initialize(run:, embedded: false, preview: false)
      super()
      @run = run
      @embedded = embedded
      @preview = preview || (run.respond_to?(:preview?) && run.preview?)
    end

    def call
      content_tag(:div, class: shell_classes, data: shell_data) do
        safe_join([progress_region, body_region, controls_region].compact)
      end
    end

    private

    def shell_data
      {
        testid: "onboarding-card-shell",
        flow_key: @run.flow_key,
        step_key: @run.current_step_key,
        embedded: @embedded,
        preview: @preview
      }
    end

    def shell_classes
      if @embedded
        "flex w-full flex-col gap-6"
      else
        "mx-auto flex w-full max-w-3xl flex-col gap-6 p-4 sm:p-8"
      end
    end

    def body_region
      content_tag(:div, content, class: "w-full", data: { testid: "onboarding-card-body" })
    end

    def progress_region
      return if @run.current_step && !@run.current_step.show_progress?

      content_tag(:div, class: "w-full") { render ProgressComponent.new(run: @run) }
    end

    def controls_region
      render ControlsComponent.new(run: @run, preview: @preview)
    end
  end
end
