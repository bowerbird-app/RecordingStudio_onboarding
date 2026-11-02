# frozen_string_literal: true

module RecordingStudioOnboarding
  module Admin
    class RunsScreen < RecordingStudioAdmin::Screen
      key "onboarding_runs"
      title "Flow runs"
      subtitle "Filter and inspect onboarding runs"
      blast_radius :site

      query { |_context| FlowRun.order(started_at: :desc) }

      filter :date_range, field: :started_at, default: :last_30_days
      filter :flow_key,
             options: -> { RecordingStudioOnboarding.configuration.flows.keys.map(&:to_s) },
             searchable: true
      filter :status, options: -> { FlowRun::STATUSES }, searchable: true
      filter :scope_type,
             options: -> { FlowRun.distinct.order(:scope_type).pluck(:scope_type) },
             searchable: true
      filter_presentation :modal, inline_count: 2

      summary do
        label "Runs"
        change_good_when :up
      end

      table do
        column :id, title: "UUID", value: ->(row, _ctx) { row.id.to_s }
        column :flow_key, title: "Flow"
        column :status
        column :scope_type, title: "Scope"
        column :current_step_key, title: "Step"
        column :started_at
        column :completed_at
        action :view,
               text: "View",
               url: ->(row, _ctx) { RecordingStudioOnboarding::Admin::Paths.admin_run_path(row) }
        action :reset,
               text: "Reset",
               method: :post,
               confirm: "Reset this run to the first step?",
               url: ->(row, _ctx) { RecordingStudioOnboarding::Admin::Paths.admin_reset_run_path(row) }
        action :restart,
               text: "Restart",
               method: :post,
               confirm: "Dismiss this run and start a new one?",
               url: ->(row, _ctx) { RecordingStudioOnboarding::Admin::Paths.admin_restart_run_path(row) }
        paginate per_page: 25
      end
    end
  end
end
