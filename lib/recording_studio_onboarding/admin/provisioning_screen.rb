# frozen_string_literal: true

module RecordingStudioOnboarding
  module Admin
    class ProvisioningScreen < RecordingStudioAdmin::Screen
      key "onboarding_provisioning"
      title "Provisioning executions"
      subtitle "Idempotent provisioner runs and failures"
      blast_radius :site

      query { |_context| ProvisioningExecution.order(created_at: :desc) }

      filter :date_range, field: :created_at, default: :last_30_days
      filter :provisioner,
             options: -> { RecordingStudioOnboarding.configuration.provisioners.keys.map(&:to_s) },
             searchable: true
      filter :status, options: -> { ProvisioningExecution::STATUSES }, searchable: true
      filter_presentation :modal, inline_count: 2

      summary do
        label "Executions"
        change_good_when :up
      end

      table do
        column :id, title: "UUID", value: ->(row, _ctx) { row.id.to_s }
        column :provisioner
        column :status
        column :idempotency_key, title: "Idempotency key"
        column :started_at
        column :completed_at
        action :view,
               text: "View",
               url: ->(row, _ctx) { RecordingStudioOnboarding::Admin::Paths.admin_provisioning_path(row) }
        action :retry,
               text: "Retry",
               method: :post,
               confirm: "Retry this failed provisioning execution?",
               visible_if: ->(row, _ctx) { row.failed? },
               url: ->(row, _ctx) { RecordingStudioOnboarding::Admin::Paths.admin_retry_provisioning_path(row) }
        paginate per_page: 25
      end
    end
  end
end
