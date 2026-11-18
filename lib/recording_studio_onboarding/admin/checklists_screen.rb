# frozen_string_literal: true

module RecordingStudioOnboarding
  module Admin
    class ChecklistsScreen < RecordingStudioAdmin::Screen
      key "onboarding_checklists"
      title "Setup checklists"
      subtitle "Registered checklists and the line each item shows"
      blast_radius :site

      query { |_context| RecordingStudioOnboarding::Admin.checklist_rows }

      summary do
        label "Checklist items"
        hide_change
        hide_period
      end

      table do
        column :checklist_key, title: "Checklist"
        column :scope
        column :item_key, title: "Item"
        column :next_step, title: "Next step"
        paginate per_page: 50
      end
    end
  end
end
