# frozen_string_literal: true

module RecordingStudioOnboarding
  module Services
    # Admin-only: close an open run (if any) and start a brand-new run for the same scope.
    class RestartRun
      def self.call(...)
        new(...).call
      end

      def initialize(run, actor:)
        @run = run
        @actor = actor
      end

      def call
        raise ArgumentError, "actor is required" if @actor.nil?

        flow_key = @run.flow_key
        subject = subject_for_restart

        ActiveRecord::Base.transaction do
          close_open_run!
        end

        StartFlow.call(flow_key, actor: @actor, subject: subject)
      end

      private

      def close_open_run! # rubocop:disable Metrics/MethodLength
        @run.with_lock do
          @run.reload
          return unless @run.open?

          @run.update!(
            status: "dismissed",
            dismissed_at: Time.current
          )
          Instrumenter.instrument(
            "flow.dismissed",
            Instrumenter.flow_payload(@run, actor: @actor).merge(reason: "admin_restart")
          )
        end
      end

      def subject_for_restart
        definition = @run.definition
        return nil unless definition
        return nil if definition.scope == :user

        @run.scope
      end
    end
  end
end
