# frozen_string_literal: true

module RecordingStudioOnboarding
  module Services
    class MarkStepViewed
      def self.call(...)
        new(...).call
      end

      def initialize(run, actor: nil)
        @run = run
        @actor = actor
      end

      def call # rubocop:disable Metrics/MethodLength
        return @run unless @run.open?

        @run.with_lock do
          ReconcileRun.call(@run)
          progress = StepProgress.find_or_create_by!(
            flow_run: @run,
            step_key: @run.current_step_key
          ) do |row|
            row.status = "pending"
          end

          if progress.first_viewed_at.blank?
            progress.update!(first_viewed_at: Time.current)
            Instrumenter.instrument(
              "step.viewed",
              Instrumenter.flow_payload(@run, actor: @actor, step_key: @run.current_step_key)
            )
          end

          auto_advance_if_complete!
          @run.reload
        end
      end

      private

      def auto_advance_if_complete!
        step = @run.current_step
        return unless step&.complete_when
        return unless step.complete_when.call(@run)

        TransitionRun.call(@run, action: :advance, actor: @actor || @run.initiating_actor, from: step.key)
      end
    end
  end
end
