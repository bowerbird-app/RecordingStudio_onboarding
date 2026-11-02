# frozen_string_literal: true

module RecordingStudioOnboarding
  module Admin
    class ProvisioningResource < RecordingStudioAdmin::Resource
      key "onboarding_provisioning"
      section "onboarding"
      title "Provisioning"
      blast_radius :site

      action :retry,
             text: "Retry",
             method: :post,
             required_role: :admin,
             url: ->(row, _ctx) { RecordingStudioOnboarding::Admin::Paths.admin_retry_provisioning_path(row) }
    end
  end
end
