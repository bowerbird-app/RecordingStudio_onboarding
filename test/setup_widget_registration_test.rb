# frozen_string_literal: true

require "test_helper"

class SetupWidgetRegistrationTest < Minitest::Test
  def test_registration_is_a_noop_when_dashboard_is_not_loaded
    refute defined?(::RecordingStudioDashboard)

    require File.expand_path("../app/components/recording_studio_onboarding/setup_widget.rb", __dir__)

    assert_nil RecordingStudioOnboarding::SetupWidget.register_dashboard_widget!
  end

  def test_prepare_raises_when_the_checklist_name_is_missing
    require File.expand_path("../app/components/recording_studio_onboarding/setup_widget.rb", __dir__)

    assert_raises(KeyError) do
      RecordingStudioOnboarding::SetupWidget.prepare(Object.new, {})
    end
    assert_raises(ArgumentError) do
      RecordingStudioOnboarding::SetupWidget.prepare(Object.new, { checklist: nil })
    end
  end
end
