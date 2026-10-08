# frozen_string_literal: true

require "test_helper"

class UsersRegistrationIntegrationTest < Minitest::Test
  def test_documents_missing_password_and_oauth_hooks
    source = File.read(
      File.expand_path("../lib/recording_studio_onboarding/users_registration_integration.rb", __dir__)
    )

    assert_includes source, "otp.registration_completed.recording_studio_user"
    assert_includes source, "Password registration and OmniAuth new-account creation do not emit a public"
    assert_includes source, "RecordingStudio_users"
  end

  def test_install_is_idempotent
    RecordingStudioOnboarding::UsersRegistrationIntegration.instance_variable_set(:@installed, false)
    RecordingStudioOnboarding::UsersRegistrationIntegration.install!
    RecordingStudioOnboarding::UsersRegistrationIntegration.install!
    assert RecordingStudioOnboarding::UsersRegistrationIntegration.instance_variable_get(:@installed)
  ensure
    RecordingStudioOnboarding::UsersRegistrationIntegration.instance_variable_set(:@installed, false)
  end
end
