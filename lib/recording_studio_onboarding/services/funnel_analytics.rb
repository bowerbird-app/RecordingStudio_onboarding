# frozen_string_literal: true

module RecordingStudioOnboarding
  module Services
    # SQL aggregates for drop-off analytics (§25). No separate analytics store.
    class FunnelAnalytics # rubocop:disable Metrics/ClassLength
      StepRow = Struct.new(
        :step_key,
        :reached,
        :continued_pct,
        :dismissals,
        :median_seconds,
        keyword_init: true
      )

      Summary = Struct.new(
        :flow_key,
        :total_runs,
        :completed,
        :dismissed,
        :completion_rate,
        :dismissal_rate,
        :steps,
        keyword_init: true
      )

      def self.call(...)
        new(...).call
      end

      def initialize(flow_key:, from: nil, to: nil)
        @flow_key = flow_key.to_s
        @from = from
        @to = to
      end

      def call # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        definition = RecordingStudioOnboarding.configuration.flow_for(@flow_key)
        raise KeyError, "No flow registered for #{@flow_key.inspect}" unless definition

        runs = scoped_runs
        totals = status_counts(runs)
        total = totals.values.sum
        steps = definition.step_keys.map { |key| build_step_row(key, runs) }

        Summary.new(
          flow_key: @flow_key,
          total_runs: total,
          completed: totals["completed"] || 0,
          dismissed: totals["dismissed"] || 0,
          completion_rate: rate(totals["completed"], total),
          dismissal_rate: rate(totals["dismissed"], total),
          steps: steps
        )
      end

      private

      def scoped_runs
        scope = FlowRun.for_flow(@flow_key)
        scope = scope.where("started_at >= ?", @from) if @from
        scope = scope.where("started_at <= ?", @to) if @to
        scope
      end

      def status_counts(runs)
        runs.group(:status).count
      end

      def build_step_row(step_key, runs)
        reached = reached_count(step_key, runs)
        next_key = next_step_key(step_key)
        continued = next_key ? reached_count(next_key, runs) : reached
        StepRow.new(
          step_key: step_key.to_s,
          reached: reached,
          continued_pct: rate(continued, reached),
          dismissals: dismissals_at(step_key, runs),
          median_seconds: median_step_seconds(step_key, runs)
        )
      end

      def next_step_key(step_key)
        keys = RecordingStudioOnboarding.configuration.flow_for(@flow_key).step_keys
        index = keys.index(step_key.to_sym)
        return nil if index.nil? || index >= keys.length - 1

        keys[index + 1]
      end

      # Reached = viewed, completed, or skipped (SQL, not Ruby enumeration).
      def reached_count(step_key, runs)
        StepProgress
          .where(flow_run_id: runs.select(:id), step_key: step_key.to_s)
          .where(
            "first_viewed_at IS NOT NULL OR status IN ('completed', 'skipped')"
          )
          .count
      end

      def dismissals_at(step_key, runs)
        runs.where(status: "dismissed", current_step_key: step_key.to_s).count
      end

      def median_step_seconds(step_key, runs) # rubocop:disable Metrics/MethodLength
        sql = <<~SQL.squish
          SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY EXTRACT(EPOCH FROM (acted_at - first_viewed_at))
          ) AS median_seconds
          FROM recording_studio_onboarding_step_progresses
          WHERE flow_run_id IN (#{runs.select(:id).to_sql})
            AND step_key = #{ActiveRecord::Base.connection.quote(step_key.to_s)}
            AND status = 'completed'
            AND first_viewed_at IS NOT NULL
            AND acted_at IS NOT NULL
            AND acted_at >= first_viewed_at
        SQL
        value = ActiveRecord::Base.connection.select_value(sql)
        value&.to_f&.round
      end

      def rate(part, whole)
        return 0.0 if whole.to_i.zero?

        ((part.to_f / whole) * 100).round(1)
      end
    end
  end
end
