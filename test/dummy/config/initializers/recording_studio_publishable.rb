# frozen_string_literal: true

if defined?(RecordingStudioPublishable)
  RecordingStudioPublishable.configure do |config|
    config.layout = "recording_studio/default_layout"
    config.management_authorizer = lambda do |recording:, actor:, **|
      actor.present? &&
        recording.present? &&
        defined?(RecordingStudioAccessible) &&
        RecordingStudioAccessible.authorized?(actor: actor, recording: recording, role: :edit)
    end
    config.management_close_url_resolver = lambda do |recording:, **|
      if defined?(RecordingStudioTermsAndConditions) &&
         recording&.recordable_type == RecordingStudioTermsAndConditions::Terms.name
        RecordingStudioTermsAndConditions::Engine.routes.url_helpers.admin_term_path(
          recording,
          script_name: RecordingStudioTermsAndConditions.configuration.mount_path
        )
      else
        "/"
      end
    end
  end
end
