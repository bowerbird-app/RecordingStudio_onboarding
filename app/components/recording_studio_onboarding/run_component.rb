# frozen_string_literal: true

module RecordingStudioOnboarding
  # Host-embeddable run renderer. Turbo Frame updates transitions in place.
  class RunComponent < ViewComponent::Base
    def initialize(run:, embedded: true)
      super()
      @run = run
      @embedded = embedded
    end

    def call
      helpers.turbo_frame_tag(frame_id, data: { testid: "onboarding-run", run_id: @run.id }) do
        @run.open? ? render_open_run : render_finished_run
      end
    end

    private

    def frame_id
      "recording_studio_onboarding_run_#{@run.id}"
    end

    def render_open_run
      step = @run.current_step
      raise ArgumentError, "No current step for run #{@run.id}" unless step

      component_class = step.component.to_s.constantize
      card = component_class.new(run: @run, step: step)

      render CardShellComponent.new(run: @run, embedded: @embedded) do
        render card
      end
    end

    def render_finished_run
      event = @run.completed? ? "flow:completed" : "flow:dismissed"
      content_tag(:div, class: "flex flex-col gap-3 text-sm", data: { testid: "onboarding-run-finished" }) do
        safe_join(
          [
            content_tag(:p, "Flow #{@run.flow_key} is #{@run.status}."),
            content_tag(:div, "", data: { onboarding_event: event, run_id: @run.id, flow_key: @run.flow_key })
          ]
        )
      end
    end
  end
end
