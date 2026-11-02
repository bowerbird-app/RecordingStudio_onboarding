# frozen_string_literal: true

module RecordingStudioOnboarding
  module Admin
    OpenRunsWidget = RecordingStudioAdmin::Widget.new("onboarding.open_runs") do
      type :number
      title "Open runs"
      info "Pending or in-progress onboarding runs."
      value { FlowRun.open_runs.count }
      hide_change
      hide_period
      blast_radius :site
      link_to { |context| context.admin_screen_path("onboarding_runs") }
    end

    CompletionRateWidget = RecordingStudioAdmin::Widget.new("onboarding.completion_rate") do
      type :number
      title "Completion rate"
      info "Completed runs as a percentage of all runs."
      value do
        total = FlowRun.count
        next 0 if total.zero?

        ((FlowRun.where(status: "completed").count.to_f / total) * 100).round(1)
      end
      hide_change
      hide_period
      blast_radius :site
      link_to { |context| context.admin_screen_path("onboarding_funnel") }
    end

    FailedProvisionsWidget = RecordingStudioAdmin::Widget.new("onboarding.failed_provisions") do
      type :number
      title "Failed provisions"
      info "Provisioning executions that need a retry."
      value { ProvisioningExecution.failed.count }
      hide_change
      hide_period
      blast_radius :site
      link_to { |context| context.admin_screen_path("onboarding_provisioning") }
    end
  end
end
