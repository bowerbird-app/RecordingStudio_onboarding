# frozen_string_literal: true

module RecordingStudioOnboarding
  module Admin
    class FlowsScreen < RecordingStudioAdmin::Screen
      key "onboarding_flows"
      title "Onboarding flows"
      subtitle "Registered flows and run counts by status"
      blast_radius :site

      query { |_context| RecordingStudioOnboarding::Admin.flow_rows }

      summary do
        label "Registered flows"
        hide_change
        hide_period
      end

      table do
        column :key, title: "Flow"
        column :scope
        column :step_count, title: "Steps"
        column :version
        column :dismissible, title: "Dismissible"
        column :pending_runs, title: "Pending"
        column :in_progress_runs, title: "In progress"
        column :completed_runs, title: "Completed"
        column :dismissed_runs, title: "Dismissed"
        paginate per_page: 50
      end
    end
  end
end
