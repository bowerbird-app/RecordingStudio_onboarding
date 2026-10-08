# frozen_string_literal: true

module RecordingStudioOnboarding
  module Services
    # Explicit reset: back to first step on the latest definition version.
    class ResetRun
      def self.call(...)
        new(...).call
      end

      def initialize(run, actor:)
        @run = run
        @actor = actor
      end

      def call # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        raise ArgumentError, "actor is required" if @actor.nil?

        definition = @run.definition
        raise KeyError, "No flow registered for #{@run.flow_key.inspect}" unless definition

        @run.with_lock do
          @run.reload
          first_key = definition.first_step_key
          raise ArgumentError, "flow has no steps" if first_key.nil?

          @run.update!(
            status: "in_progress",
            flow_version: definition.version,
            current_step_key: first_key.to_s,
            started_at: Time.current,
            completed_at: nil,
            dismissed_at: nil
          )

          @run.step_progresses.delete_all
          definition.step_keys.each do |key|
            StepProgress.create!(flow_run: @run, step_key: key.to_s, status: "pending")
          end

          Instrumenter.instrument("flow.reset", Instrumenter.flow_payload(@run, actor: @actor))
          @run
        end
      end
    end
  end
end
