# frozen_string_literal: true

module RecordingStudioOnboarding
  # Shared engine route resolution for chrome / controls forms.
  module EngineRouting
    private

    def engine_path(helper_name)
      if helpers.respond_to?(helper_name)
        helpers.public_send(helper_name, @run)
      elsif helpers.respond_to?(:recording_studio_onboarding)
        helpers.recording_studio_onboarding.public_send(helper_name, @run)
      else
        RecordingStudioOnboarding::Engine.routes.url_helpers.public_send(
          helper_name, @run, script_name: "/onboarding"
        )
      end
    end
  end
end
