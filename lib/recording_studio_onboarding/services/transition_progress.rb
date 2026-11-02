# frozen_string_literal: true

module RecordingStudioOnboarding
  module Services
    module TransitionProgress
      private

      def instrument_step(event_name)
        Instrumenter.instrument(
          event_name,
          Instrumenter.flow_payload(@run, actor: @actor, step_key: @run.current_step_key)
        )
      end

      def mark_step!(status)
        progress = find_or_create_progress(@run.current_step_key)
        progress.update!(
          status: status.to_s,
          acted_by: @actor,
          acted_at: Time.current,
          first_viewed_at: progress.first_viewed_at || Time.current
        )
        instrument_step("step.completed") if status == :completed
      end

      def move_forward!
        keys = @run.definition.step_keys
        index = keys.index(@run.current_step_key.to_sym)
        next_key = index && keys[index + 1]
        next_key ? advance_to!(next_key) : complete_run!
      end

      def advance_to!(next_key)
        @run.update!(current_step_key: next_key.to_s, status: "in_progress")
        mark_viewed!(next_key)
      end

      def complete_run!
        @run.update!(status: "completed", completed_at: Time.current)
        Instrumenter.instrument("flow.completed", Instrumenter.flow_payload(@run, actor: @actor))
      end

      def mark_viewed!(step_key)
        progress = find_or_create_progress(step_key)
        return if progress.first_viewed_at.present?

        progress.update!(first_viewed_at: Time.current)
        Instrumenter.instrument(
          "step.viewed",
          Instrumenter.flow_payload(@run, actor: @actor, step_key: step_key)
        )
      end

      def find_or_create_progress(step_key)
        StepProgress.find_or_create_by!(flow_run: @run, step_key: step_key.to_s) do |row|
          row.status = "pending"
        end
      end
    end
  end
end
