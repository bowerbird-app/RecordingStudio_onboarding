# frozen_string_literal: true

require "recording_studio_onboarding/services/failure_sanitizer"
require "recording_studio_onboarding/services/provision_support"

module RecordingStudioOnboarding
  module Services
    # Host jobs report the outcome of an async provisioner.
    class FinishProvisioning
      include ProvisionSupport

      def self.complete!(execution_or_id)
        new.complete!(execution_or_id)
      end

      def self.fail!(execution_or_id, error:)
        new.fail!(execution_or_id, error: error)
      end

      def complete!(execution_or_id)
        execution = find_execution!(execution_or_id)
        instrument("provision.completed", execution) if mark_completed!(execution)
        execution
      end

      def fail!(execution_or_id, error:)
        require_exception!(error)
        execution = find_execution!(execution_or_id)
        record_failure!(execution, error)
        instrument("provision.failed", execution, error: error)
        execution
      end

      private

      def mark_completed!(execution)
        execution.with_lock do
          execution.reload
          next false if execution.completed?

          execution.update!(status: "completed", completed_at: Time.current, failure_details: nil)
          true
        end
      end

      def record_failure!(execution, error)
        execution.with_lock do
          execution.reload
          raise ArgumentError, "provisioning execution is completed" if execution.completed?

          execution.update!(
            status: "failed",
            completed_at: Time.current,
            failure_details: FailureSanitizer.call(error)
          )
        end
      end

      def require_exception!(error)
        return if error.is_a?(Exception)

        raise ArgumentError, "error must be an exception"
      end

      def find_execution!(execution_or_id)
        return execution_or_id if execution_or_id.is_a?(ProvisioningExecution)

        raise ArgumentError, "execution or id is required" if execution_or_id.blank?

        ProvisioningExecution.find(execution_or_id)
      end
    end
  end
end
