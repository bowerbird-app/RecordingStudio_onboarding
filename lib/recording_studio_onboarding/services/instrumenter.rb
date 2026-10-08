# frozen_string_literal: true

module RecordingStudioOnboarding
  module Services
    module Instrumenter
      NAMESPACE = "recording_studio_onboarding"

      module_function

      def instrument(event_name, payload = {})
        ActiveSupport::Notifications.instrument("#{event_name}.#{NAMESPACE}", payload)
      end

      def flow_payload(run, actor: nil, step_key: nil) # rubocop:disable Metrics/MethodLength
        actor_type = if actor
                       actor.class.base_class.name
                     else
                       run.initiating_actor_type
                     end
        {
          run_uuid: run.id,
          flow_key: run.flow_key,
          flow_version: run.flow_version,
          scope_type: run.scope_type,
          scope_id: run.scope_id,
          actor_type: actor_type,
          actor_id: actor&.id || run.initiating_actor_id,
          step_key: step_key || run.current_step_key,
          status: run.status
        }.compact
      end
    end
  end
end
