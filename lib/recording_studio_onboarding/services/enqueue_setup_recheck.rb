# frozen_string_literal: true

require "recording_studio_onboarding/services/refresh_setup_status"

module RecordingStudioOnboarding
  module Services
    # Enqueues a background recheck unless this actor and checklist were saved recently.
    module EnqueueSetupRecheck
      module_function

      def call(checklist_key, actor, scope)
        return if fresh?(checklist_key, actor, scope)

        ::RecordingStudioOnboarding::RecheckSetupJob.perform_later(checklist_key.to_s, gid(actor), gid(scope))
      end

      def fresh?(checklist_key, actor, scope)
        row = SetupCheck.find_by(checklist_key: checklist_key.to_s, actor: actor, scope: scope)
        return false if row.nil? || row.checked_at.nil?

        row.checked_at > Time.current - RecordingStudioOnboarding.configuration.setup_recheck_interval
      end

      def gid(record)
        record.to_global_id.to_s
      end
    end
  end
end
