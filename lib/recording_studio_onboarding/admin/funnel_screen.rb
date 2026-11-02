# frozen_string_literal: true

module RecordingStudioOnboarding
  module Admin
    class FunnelScreen < RecordingStudioAdmin::Screen
      key "onboarding_funnel"
      title "Drop-off funnel"
      subtitle "Step reach, continuation, dismissals, and median time"
      blast_radius :site

      query do |context|
        RecordingStudioOnboarding::Admin.funnel_for(context).steps.map do |step|
          FunnelRow.new(
            step_key: step.step_key,
            reached: step.reached,
            continued_pct: step.continued_pct,
            dismissals: step.dismissals,
            median_seconds: step.median_seconds
          )
        end
      end

      filter :date_range, field: :started_at, default: :last_30_days
      filter :flow_key,
             options: -> { RecordingStudioOnboarding.configuration.flows.keys.map(&:to_s) }

      summary do
        label "Completion rate %"
        value { |context| RecordingStudioOnboarding::Admin.funnel_for(context).completion_rate }
        hide_change
        hide_period
      end

      chart do
        title "Reached per step"
        type :bar
        series do |context|
          rows = Array(context.query_result&.relation)
          [
            {
              name: "Reached",
              data: rows.map { |row| { x: row.step_key, y: row.reached } }
            }
          ]
        end
      end

      table do
        column :step_key, title: "Step"
        column :reached
        column :continued_pct, title: "Continued %"
        column :dismissals
        column :median_seconds, title: "Median seconds"
        paginate per_page: 50
      end
    end
  end
end
