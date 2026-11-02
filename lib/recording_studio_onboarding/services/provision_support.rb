# frozen_string_literal: true

module RecordingStudioOnboarding
  module Services
    module ProvisionSupport
      private

      def handler_source
        RecordingStudioOnboarding.configuration.provisioner_for(@name)
      end

      def default_idempotency_key
        parts = [@name, type_name(@actor), identity(@actor)]
        parts.push(type_name(@subject), identity(@subject)) if distinct_subject?
        parts.join(":")
      end

      def distinct_subject?
        @subject && !same_record?(@actor, @subject)
      end

      def find_or_create_execution!
        RecordingStudioOnboarding::ProvisioningExecution.create_or_find_by!(
          provisioner: @name.to_s,
          idempotency_key: @idempotency_key
        ) do |record|
          record.actor = @actor
          record.subject = @subject
          record.status = "pending"
        end
      end

      def claim_completed?(execution)
        execution.reload
        execution.completed?
      end

      def claim_for_run!(execution)
        execution.with_lock do
          execution.reload
          return false if execution.completed? || execution.running?

          execution.update!(running_attributes)
          true
        end
      end

      def running_attributes
        {
          status: "running",
          started_at: Time.current,
          completed_at: nil,
          failure_details: nil,
          actor: @actor,
          subject: @subject
        }
      end

      def invoke_handler
        handler = resolve_handler
        unless handler.respond_to?(:call)
          raise ArgumentError, "Provisioner #{handler_source.inspect} does not respond to call"
        end

        handler.call(actor: @actor, subject: @subject, root: @root, context: @context)
      end

      def resolve_handler
        source = handler_source
        return source if source.respond_to?(:call)
        return source.constantize if source.is_a?(String)

        raise ArgumentError, "Unsupported provisioner #{source.inspect}"
      end

      def persist_failure!(execution, error)
        execution.with_lock do
          execution.update!(
            status: "failed",
            completed_at: Time.current,
            failure_details: FailureSanitizer.call(error)
          )
        end
      end

      def instrument(event_name, execution, error: nil)
        ActiveSupport::Notifications.instrument(
          "#{event_name}.recording_studio_onboarding",
          notification_payload(execution, error: error)
        )
      end

      def notification_payload(execution, error: nil)
        execution_payload(execution).merge(error_payload(error))
      end

      def execution_payload(execution)
        {
          execution_uuid: execution.id,
          provisioner: execution.provisioner,
          idempotency_key: execution.idempotency_key,
          actor_type: execution.actor_type,
          actor_id: execution.actor_id,
          subject_type: execution.subject_type,
          subject_id: execution.subject_id,
          status: execution.status
        }
      end

      def error_payload(error)
        return {} unless error

        { error_class: error.class.name }
      end

      def type_name(record)
        record.class.base_class.name
      end

      def identity(record)
        record.id
      end

      def same_record?(left, right)
        type_name(left) == type_name(right) && identity(left) == identity(right)
      end
    end
  end
end
