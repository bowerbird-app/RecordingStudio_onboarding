# frozen_string_literal: true

module RecordingStudioOnboarding
  module Services
    module Instrumenter
      NAMESPACE = "recording_studio_onboarding"

      module_function

      def instrument(event_name, payload = {})
        ActiveSupport::Notifications.instrument("#{event_name}.#{NAMESPACE}", payload)
      end

      def flow_payload(run, actor: nil, step_key: nil)
        identity_payload(run, actor).merge(
          flow_key: run.flow_key,
          flow_version: run.flow_version,
          step_key: step_key || run.current_step_key,
          status: run.status
        ).compact
      end

      def identity_payload(run, actor)
        {
          run_uuid: run.id,
          scope_type: run.scope_type,
          scope_id: run.scope_id,
          actor_type: actor_type_for(run, actor),
          actor_id: actor&.id || run.initiating_actor_id
        }
      end

      def actor_type_for(run, actor)
        actor ? actor.class.base_class.name : run.initiating_actor_type
      end
    end
  end
end
