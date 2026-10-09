# frozen_string_literal: true

require "test_helper"

# Dummy boots with OTP off. RecordingStudio_users 0.18+ omits OTP routes when
# otp_enabled is false, so these paths must be unreachable (clean 404).
class OtpRoutesDisabledTest < ActionDispatch::IntegrationTest
  OTP_PATHS = [
    [:get, "/users/sign_up/otp"],
    [:post, "/users/sign_up/otp"],
    [:get, "/users/sign_up/verify"],
    [:post, "/users/sign_up/verify"],
    [:post, "/users/sign_up/resend"],
    [:get, "/users/sign_in/otp"],
    [:post, "/users/sign_in/otp"],
    [:get, "/users/sign_in/verify"],
    [:post, "/users/sign_in/verify"],
    [:post, "/users/sign_in/resend"],
    [:get, "/recording_studio_users/auth/sign_up/otp"],
    [:post, "/recording_studio_users/auth/sign_up/otp"],
    [:get, "/recording_studio_users/auth/sign_up/verify"],
    [:post, "/recording_studio_users/auth/sign_up/verify"],
    [:post, "/recording_studio_users/auth/sign_up/resend"],
    [:get, "/recording_studio_users/auth/sign_in/otp"],
    [:post, "/recording_studio_users/auth/sign_in/otp"],
    [:get, "/recording_studio_users/auth/sign_in/verify"],
    [:post, "/recording_studio_users/auth/sign_in/verify"],
    [:post, "/recording_studio_users/auth/sign_in/resend"]
  ].freeze

  test "otp is off in the dummy default config" do
    refute RecordingStudioUser.config.otp_enabled?
  end

  test "every OTP path returns not found when OTP is off" do
    OTP_PATHS.each do |http_method, path|
      public_send(http_method, path)
      assert_response :not_found, "#{http_method.upcase} #{path} should be unreachable"
      refute_match(/NoMethodError|undefined method/i, response.body)
    end
  end

  test "password auth screens and onboarding pages do not link to OTP paths" do
    get new_user_session_path
    assert_response :success
    refute_includes response.body, "/sign_in/otp"
    refute_includes response.body, "/sign_in/verify"
    refute_includes response.body, "/sign_in/resend"

    get new_user_registration_path
    assert_response :success
    refute_includes response.body, "/sign_up/otp"
    refute_includes response.body, "/sign_up/verify"
    refute_includes response.body, "/sign_up/resend"

    get "/flows"
    assert_response :redirect
    follow_redirect!
    # Unauthenticated flows bounce to sign-in; that page must not advertise OTP.
    assert_response :success
    refute_includes response.body, "/sign_up/otp"
    refute_includes response.body, "/sign_in/otp"
  end
end
