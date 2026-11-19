# frozen_string_literal: true

module RecordingStudioOnboarding
  module Admin
    class OnboardingSection < RecordingStudioAdmin::Section
      key "onboarding"
      title "Onboarding"
      subtitle "Flows, card previews, runs, funnel, provisioning, and setup"
      blast_radius :site

      widget "onboarding.open_runs"
      widget "onboarding.completion_rate"
      widget "onboarding.failed_provisions"

      link :flows, text: "Flows", url: ->(context) { context.admin_screen_path("onboarding_flows") }
      link :previews, text: "Card previews", url: ->(context) { context.admin_screen_path("onboarding_previews") }
      link :runs, text: "Runs", url: ->(context) { context.admin_screen_path("onboarding_runs") }
      link :funnel, text: "Drop-off funnel", url: ->(context) { context.admin_screen_path("onboarding_funnel") }
      link :provisioning,
           text: "Provisioning",
           url: ->(context) { context.admin_screen_path("onboarding_provisioning") }
      link :checklists,
           text: "Setup checklists",
           url: ->(context) { context.admin_screen_path("onboarding_checklists") }
      link :setup_lookup,
           text: "Look up setup",
           url: ->(_context) { RecordingStudioOnboarding::Admin::Paths.admin_setup_lookup_path }
    end
  end
end
