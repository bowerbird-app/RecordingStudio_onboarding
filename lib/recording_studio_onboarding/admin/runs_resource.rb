# frozen_string_literal: true

module RecordingStudioOnboarding
  module Admin
    class RunsResource < RecordingStudioAdmin::Resource
      key "onboarding_runs"
      section "onboarding"
      title "Onboarding runs"
      blast_radius :site

      action :reset,
             text: "Reset",
             method: :post,
             required_role: :admin,
             url: ->(row, _ctx) { RecordingStudioOnboarding::Admin::Paths.admin_reset_run_path(row) }
      action :restart,
             text: "Restart",
             method: :post,
             required_role: :admin,
             url: ->(row, _ctx) { RecordingStudioOnboarding::Admin::Paths.admin_restart_run_path(row) }
    end
  end
end
