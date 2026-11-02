# frozen_string_literal: true

module RecordingStudioOnboarding
  module Services
    class MedianStepSeconds
      SQL = <<~SQL.squish
        SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (
          ORDER BY EXTRACT(EPOCH FROM (acted_at - first_viewed_at))
        ) AS median_seconds
        FROM recording_studio_onboarding_step_progresses
        WHERE flow_run_id IN (%<run_ids>s)
          AND step_key = %<step_key>s
          AND status = 'completed'
          AND first_viewed_at IS NOT NULL
          AND acted_at IS NOT NULL
          AND acted_at >= first_viewed_at
      SQL

      def self.call(step_key, runs)
        new(step_key, runs).call
      end

      def initialize(step_key, runs)
        @step_key = step_key
        @runs = runs
      end

      def call
        value = ActiveRecord::Base.connection.select_value(sql)
        value&.to_f&.round
      end

      private

      def sql
        format(
          SQL,
          run_ids: @runs.select(:id).to_sql,
          step_key: ActiveRecord::Base.connection.quote(@step_key.to_s)
        )
      end
    end
  end
end
