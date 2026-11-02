# frozen_string_literal: true

require "recording_studio_onboarding/provision_failed"
require "recording_studio_onboarding/services/provision_support"

module RecordingStudioOnboarding
  module Services
    # Executes a registered provisioner with DB-backed idempotency tracking.
    class Provision
      include ProvisionSupport

      attr_reader :idempotency_key

      def self.call(name, **)
        new(name, **).call
      end

      def initialize(name, actor:, **options)
        @name = name.to_sym
        @actor = actor
        @subject = options[:subject]
        @root = options[:root]
        @context = options[:context] || {}
        @idempotency_key = options[:idempotency_key].presence || default_idempotency_key
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

      def run_handler!(execution)
        instrument("provision.started", execution)
        invoke_handler
        execution.update!(status: "completed", completed_at: Time.current, failure_details: nil)
        instrument("provision.completed", execution)
        execution
      rescue StandardError => e
        persist_failure!(execution, e)
        instrument("provision.failed", execution, error: e)
        raise ProvisionFailed.new(e, execution: execution)
      end
    end
  end
end
