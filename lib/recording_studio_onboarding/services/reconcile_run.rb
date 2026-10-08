# frozen_string_literal: true

module RecordingStudioOnboarding
  module Services
    # Aligns an open run's current_step_key with the live flow definition.
    # Completed/dismissed runs are never reopened.
    class ReconcileRun
      def self.call(...)
        new(...).call
      end

      def initialize(run)
        @run = run
      end

      def call # rubocop:disable Metrics/MethodLength
        return @run unless @run.open?

        definition = @run.definition
        return @run if definition.nil?

        keys = definition.step_keys
        return complete_empty!(definition) if keys.empty?

        unless keys.include?(@run.current_step_key.to_sym)
          next_key = next_existing_step(keys)
          @run.update!(current_step_key: next_key.to_s) if next_key
        end

        ensure_step_rows!(definition)
        @run
      end

      private

      def next_existing_step(keys)
        done = @run.step_progresses
                   .where(status: %w[completed skipped])
                   .pluck(:step_key)
                   .map(&:to_sym)
        keys.find { |key| !done.include?(key) } || keys.last
      end

      def ensure_step_rows!(definition)
        definition.step_keys.each do |key|
          StepProgress.find_or_create_by!(flow_run: @run, step_key: key.to_s) do |row|
            row.status = "pending"
          end
        end
      end

      def complete_empty!(definition)
        @run.update!(
          status: "completed",
          completed_at: Time.current,
          flow_version: definition.version
        )
        @run
      end
    end
  end
end
