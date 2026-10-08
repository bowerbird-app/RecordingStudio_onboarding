# frozen_string_literal: true

module AdminScreens
  class RootSection < RecordingStudioAdmin::Section
    key "root"
    title "Admin"
    subtitle "Site administration"
    blast_radius :site

    link :onboarding,
         text: "Onboarding",
         url: ->(context) { context.admin_section_path("onboarding") }
  end
end
