# frozen_string_literal: true

module RecordingStudioOnboarding
  module Services
    # Executes a registered provisioner with DB-backed idempotency tracking.
    class Provision # rubocop:disable Metrics/ClassLength
      def self.call(name, **)
        new(name, **).call
      end

      # rubocop:disable-next Metrics/ParameterLists -- stable provisioner call shape
      def initialize(name, actor:, subject: nil, root: nil, context: {}, idempotency_key: nil)
        @name = name.to_sym
        @actor = actor
        @subject = subject
        @root = root
        @context = context || {}
        @idempotency_key = idempotency_key.presence || default_idempotency_key
      end

      def call
        raise ArgumentError, "actor is required" if @actor.nil?
        raise KeyError, "No provisioner registered for #{@name.inspect}" unless handler_source

        execution = find_or_create_execution!
        return execution if claim_completed?(execution)
        return execution unless claim_for_run!(execution)

        run_handler!(execution)
      end

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

      # Returns true when this caller owns the run.
      def claim_for_run!(execution) # rubocop:disable Metrics/MethodLength
        execution.with_lock do
          execution.reload
          return false if execution.completed? || execution.running?

          execution.update!(
            status: "running",
            started_at: Time.current,
            completed_at: nil,
            failure_details: nil,
            actor: @actor,
            subject: @subject
          )
          true
        end
      end

      def run_handler!(execution)
        instrument("provision.started", execution)
        invoke_handler
        execution.update!(status: "completed", completed_at: Time.current, failure_details: nil)
        instrument("provision.completed", execution)
        execution
      rescue StandardError => e
        persist_failure!(execution, e)
        instrument("provision.failed", execution, error: e)
        raise
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

      def instrument(event_name, execution, error: nil) # rubocop:disable Metrics/MethodLength
        payload = {
          execution_uuid: execution.id,
          provisioner: execution.provisioner,
          idempotency_key: execution.idempotency_key,
          actor_type: execution.actor_type,
          actor_id: execution.actor_id,
          subject_type: execution.subject_type,
          subject_id: execution.subject_id,
          status: execution.status
        }
        payload[:error_class] = error.class.name if error
        ActiveSupport::Notifications.instrument(
          "#{event_name}.recording_studio_onboarding",
          payload
        )
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
