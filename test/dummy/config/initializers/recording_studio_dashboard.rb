# frozen_string_literal: true

return unless defined?(RecordingStudioDashboard)

studio_dashboard_registered = lambda do
  RecordingStudioDashboard.registry.dashboard(:studio)
  true
rescue KeyError
  false
end

Rails.application.config.to_prepare do
  next unless defined?(RecordingStudioDashboard)
  next if studio_dashboard_registered.call

  RecordingStudioOnboarding::SetupWidget.register_dashboard_widget!
  RecordingStudioDashboard.register(:studio) do
    row :setup do
      widget :onboarding_setup, span: 12, config: { checklist: :studio }
    end
  end
end
