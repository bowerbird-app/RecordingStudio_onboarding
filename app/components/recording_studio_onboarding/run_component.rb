# frozen_string_literal: true

module RecordingStudioOnboarding
  # Host-embeddable run renderer. Turbo Frame updates transitions in place.
  class RunComponent < ViewComponent::Base
    def initialize(run:, embedded: true)
      super()
      @run = run
      @embedded = embedded
    end

    def before_render
      path = before_onboarding_path
      return if path.blank?
      return if controller.performed?

      controller.redirect_to path
    end

    def call
      return if before_onboarding_path.present?

      helpers.turbo_frame_tag(frame_id, data: { testid: "onboarding-run", run_id: @run.id }) do
        @run.open? ? render_open_run : render_finished_run
      end
    end

    private

    def before_onboarding_path
      return @before_onboarding_path if defined?(@before_onboarding_path)

      actor = resolve_actor
      @before_onboarding_path = RecordingStudioOnboarding.before_onboarding_redirect_to(
        controller,
        actor: actor,
        return_path: helpers.request&.fullpath
      )
    end

    def resolve_actor
      resolver = RecordingStudioOnboarding.configuration.current_actor
      if resolver.respond_to?(:call)
        resolver.call(controller)
      elsif helpers.respond_to?(:current_user)
        helpers.current_user
      end
    end

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
