# frozen_string_literal: true

module RecordingStudioOnboarding
  module Admin
    class PreviewsScreen < RecordingStudioAdmin::Screen
      key "onboarding_previews"
      title "Card previews"
      subtitle "Render any step in the card shell without writing runs"
      blast_radius :site

      query { |_context| RecordingStudioOnboarding::Admin.preview_rows }

      table do
        column :flow_key, title: "Flow"
        column :step_key, title: "Step"
        column :component
        action :preview,
               text: "Preview",
               url: lambda { |row, _context|
                 RecordingStudioOnboarding::Admin::Paths.admin_preview_path(row.flow_key, row.step_key)
               }
        paginate per_page: 50
      end
    end
  end
end
