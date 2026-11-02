# frozen_string_literal: true

require "recording_studio_onboarding/services/transition_progress"

module RecordingStudioOnboarding
  module Services
    # Shared advance / back / skip / dismiss transitions with row locking.
    class TransitionRun
      include TransitionProgress

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

      def call
        raise ArgumentError, "Unsupported action #{@action.inspect}" unless ACTIONS.include?(@action)
        raise ArgumentError, "actor is required" if @actor.nil?

        @run.with_lock do
          apply_locked_transition!
          @run
        end
      end

      private

      def apply_locked_transition!
        @run.reload
        return unless @run.open?

        ReconcileRun.call(@run)
        @run.reload
        return if stale_from?

        perform_action!
      end

      def perform_action!
        case @action
        when :advance then advance!
        when :back then back!
        when :skip then skip!
        when :dismiss then dismiss!
        end
      end

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
        instrument_step("step.skipped")
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
      end
    end
  end
end
