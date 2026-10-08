# frozen_string_literal: true

require "test_helper"

class UsersRegistrationIntegrationTest < Minitest::Test
  def test_subscribes_to_unified_registration_completed_event
    source = File.read(
      File.expand_path("../lib/recording_studio_onboarding/users_registration_integration.rb", __dir__)
    )

    assert_includes source, "registration.completed.recording_studio_user"
    assert_includes source, "RecordingStudio_users >= 0.15.0"
    assert_includes source, "%i[password oauth otp]"
    refute_includes source, "subscribe(OTP_EVENT)"
    refute_includes source, "Password registration and OmniAuth new-account creation do not emit a public"
  end

  def test_gemspec_requires_recording_studio_user_0_15
    gemspec = File.read(File.expand_path("../recording_studio_onboarding.gemspec", __dir__))
    gemfile = File.read(File.expand_path("../Gemfile", __dir__))
    dummy_gemfile = File.read(File.expand_path("dummy/Gemfile", __dir__))

    assert_includes gemspec, 'spec.add_dependency "recording_studio_user", ">= 0.15.0"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_users", tag: "v0.15.0"'
    assert_includes dummy_gemfile, 'github: "bowerbird-app/RecordingStudio_users", tag: "v0.15.0"'
  end

  def test_install_is_idempotent
    RecordingStudioOnboarding::UsersRegistrationIntegration.instance_variable_set(:@installed, false)
    RecordingStudioOnboarding::UsersRegistrationIntegration.install!
    RecordingStudioOnboarding::UsersRegistrationIntegration.install!
    assert RecordingStudioOnboarding::UsersRegistrationIntegration.instance_variable_get(:@installed)
  ensure
    RecordingStudioOnboarding::UsersRegistrationIntegration.instance_variable_set(:@installed, false)
  end

  def test_supported_methods_cover_password_oauth_and_otp
    methods = RecordingStudioOnboarding::UsersRegistrationIntegration::METHODS
    assert_equal %i[password oauth otp], methods

    methods.each do |method|
      assert RecordingStudioOnboarding::UsersRegistrationIntegration.supported_method?(method: method)
    end

    refute RecordingStudioOnboarding::UsersRegistrationIntegration.supported_method?(method: :sms)
    refute RecordingStudioOnboarding::UsersRegistrationIntegration.supported_method?({})
  end

  def test_legacy_otp_event_constant_is_documented_but_not_subscribed
    source = File.read(
      File.expand_path("../lib/recording_studio_onboarding/users_registration_integration.rb", __dir__)
    )
    assert_equal(
      "otp.registration_completed.recording_studio_user",
      RecordingStudioOnboarding::UsersRegistrationIntegration::LEGACY_OTP_EVENT
    )
    assert_includes source, "LEGACY_OTP_EVENT"
    refute_match(/subscribe\(\s*LEGACY_OTP_EVENT/, source)
  end
end
