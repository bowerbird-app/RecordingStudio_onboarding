# frozen_string_literal: true

module RecordingStudioOnboarding
  module Services
    # Shared advance / back / skip / dismiss transitions with row locking.
    class TransitionRun
      ACTIONS = %i[advance back skip dismiss].freeze

      def self.call(...)
        new(...).call
      end

      def initialize(run, action:, actor:, from: nil)
        @run = run
        @action = action.to_sym
        @actor = actor
        @from = from&.to_sym
      end

      def call # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
        raise ArgumentError, "Unsupported action #{@action.inspect}" unless ACTIONS.include?(@action)
        raise ArgumentError, "actor is required" if @actor.nil?

        @run.with_lock do
          @run.reload
          return @run unless @run.open?

          ReconcileRun.call(@run)
          @run.reload

          return @run if stale_from?

          case @action
          when :advance then advance!
          when :back then back!
          when :skip then skip!
          when :dismiss then dismiss!
          end

          @run
        end
      end

      private

      def stale_from?
        return false if @from.nil? || @action == :dismiss

        @run.current_step_key.to_sym != @from
      end

      def advance!
        mark_step!(:completed)
        move_forward!
      end

      def skip!
        step = @run.current_step
        raise ArgumentError, "step is not skippable" if step && !step.skippable?

        mark_step!(:skipped)
        Instrumenter.instrument(
          "step.skipped",
          Instrumenter.flow_payload(@run, actor: @actor, step_key: @run.current_step_key)
        )
        move_forward!
      end

      def back!
        keys = @run.definition.step_keys
        index = keys.index(@run.current_step_key.to_sym)
        return if index.nil? || index.zero?

        previous = keys[index - 1]
        @run.update!(current_step_key: previous.to_s)
        mark_viewed!(previous)
      end

      def dismiss!
        return unless @run.definition&.dismissible

        @run.update!(status: "dismissed", dismissed_at: Time.current)
        Instrumenter.instrument("flow.dismissed", Instrumenter.flow_payload(@run, actor: @actor))
        # Non-dismissible: leave status as-is (exit only); host decides presentation.
      end

      def mark_step!(status) # rubocop:disable Metrics/MethodLength
        progress = StepProgress.find_or_create_by!(flow_run: @run, step_key: @run.current_step_key) do |row|
          row.status = "pending"
        end
        progress.update!(
          status: status.to_s,
          acted_by: @actor,
          acted_at: Time.current,
          first_viewed_at: progress.first_viewed_at || Time.current
        )

        return unless status == :completed

        Instrumenter.instrument(
          "step.completed",
          Instrumenter.flow_payload(@run, actor: @actor, step_key: @run.current_step_key)
        )
      end

      def move_forward!
        keys = @run.definition.step_keys
        index = keys.index(@run.current_step_key.to_sym)
        next_key = index && keys[index + 1]

        if next_key
          @run.update!(current_step_key: next_key.to_s, status: "in_progress")
          mark_viewed!(next_key)
        else
          @run.update!(status: "completed", completed_at: Time.current)
          Instrumenter.instrument("flow.completed", Instrumenter.flow_payload(@run, actor: @actor))
        end
      end

      def mark_viewed!(step_key)
        progress = StepProgress.find_or_create_by!(flow_run: @run, step_key: step_key.to_s) do |row|
          row.status = "pending"
        end
        return if progress.first_viewed_at.present?

        progress.update!(first_viewed_at: Time.current)
        Instrumenter.instrument(
          "step.viewed",
          Instrumenter.flow_payload(@run, actor: @actor, step_key: step_key)
        )
      end
    end
  end
end
