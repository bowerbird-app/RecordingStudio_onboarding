# frozen_string_literal: true

require "test_helper"

# Runs only when the dummy bundle omits RS Terms (gemfiles/without_terms.gemfile).
class WithoutTermsOnboardingTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    skip "RS Terms is loaded — use the with-terms bundle for Agree-gate tests" if defined?(RecordingStudioTermsAndConditions)

    RecordingStudioOnboarding::Gates::TermsAndConditions.register_if_present!

    @user = User.create!(
      email: "no-terms-#{SecureRandom.hex(4)}@example.com",
      password: "Password",
      password_confirmation: "Password",
      registered_with: "password",
      confirmed_at: Time.current
    )
  end

  test "terms constant is undefined and no terms gate is registered" do
    refute defined?(RecordingStudioTermsAndConditions)
    refute defined?(RecordingStudioPublishable)

    gates = RecordingStudioOnboarding.configuration.before_onboarding_gates
    refute gates.any?(RecordingStudioOnboarding::Gates::TermsAndConditions)

    path = RecordingStudioOnboarding.before_onboarding_redirect_to(
      nil,
      actor: @user,
      return_path: "/onboarding/runs/example"
    )
    assert_nil path
  end

  test "terms acceptance paths are absent" do
    route_names = Rails.application.routes.named_routes.names
    refute_includes route_names, :recording_studio_terms_and_conditions
    refute_includes route_names, :recording_studio_publishable

    get "/recording_studio_terms_and_conditions/acceptance"
    assert_response :not_found

    get "/recording_studio_terms_and_conditions"
    assert_response :not_found
  end

  test "user goes straight to onboarding without terms" do
    run = RecordingStudioOnboarding.start(:account_setup, actor: @user)
    sign_in @user

    get recording_studio_onboarding.run_path(run)
    assert_response :success
    assert_includes path, "/onboarding/runs/#{run.id}"
    assert_select "[data-testid=onboarding-progress], [data-testid=onboarding-run]", minimum: 1
  end

  test "flows start redirects to the run page immediately" do
    sign_in @user

    post start_flows_path, params: { flow_key: "account_setup" }
    run = RecordingStudioOnboarding.active_run(:account_setup, actor: @user)
    assert run
    assert_redirected_to recording_studio_onboarding.run_path(run)

    follow_redirect!
    assert_response :success
  end
end
