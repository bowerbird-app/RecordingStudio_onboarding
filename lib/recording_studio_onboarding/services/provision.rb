# frozen_string_literal: true

require "recording_studio_onboarding/provision_failed"
require "recording_studio_onboarding/services/accessible_authorization"
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

      ALLOWED_KEYWORDS = %i[subject root context idempotency_key].freeze

      def initialize(name, actor:, **options)
        reject_unknown_keywords!(options)
        @name = name.to_sym
        @actor = actor
        assign_options(options)
      end

      def call
        raise ArgumentError, "actor is required" if @actor.nil?
        raise KeyError, "No provisioner registered for #{@name.inspect}" unless handler_source

        authorize_targets!

        execution = find_or_create_execution!
        return execution if claim_completed?(execution)
        return execution unless claim_for_run!(execution)

        run_handler!(execution)
      end

      private

      def authorize_targets!
        [@subject, @root].compact.uniq.each do |record|
          next if AccessibleAuthorization.allowed?(actor: @actor, record: record)

          raise RecordingStudioOnboarding::Unauthorized, "not authorized to provision this record"
        end
      end

      def reject_unknown_keywords!(options)
        unknown = options.keys - ALLOWED_KEYWORDS
        raise ArgumentError, "Unknown keywords: #{unknown.map(&:inspect).join(', ')}" if unknown.any?
      end

      def assign_options(options)
        @subject = options[:subject]
        @root = options[:root]
        @context = options[:context] || {}
        @idempotency_key = options[:idempotency_key].presence || default_idempotency_key
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
        raise ProvisionFailed.new(e, execution: execution)
      end
    end
  end
end
