# frozen_string_literal: true

require "test_helper"

class OnboardingDemosTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(
      email: "demos-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      confirmed_at: Time.current
    )
    sign_in @user
  end

  test "layout gallery index lists every variant" do
    get "/demos/onboarding"
    assert_response :success
    %w[splash top-card no-image buttons-left buttons-right buttons-full].each do |variant|
      assert_select "a[href=?]", "/demos/onboarding/#{variant}"
    end
  end

  test "splash demo lands on splash layout with full continue" do
    get "/demos/onboarding/splash"
    assert_redirected_to %r{/onboarding/runs/}
    follow_redirect!
    assert_response :success
    assert_select "[data-testid='onboarding-page'][data-layout='splash']"
    assert_select "[data-testid='control-advance']"
    assert_select "[data-testid='control-skip']"
    assert_select "[data-testid='control-exit']", count: 0
  end

  test "top-card demo lands on top-card layout" do
    get "/demos/onboarding/top-card"
    follow_redirect!
    assert_select "[data-testid='onboarding-page'][data-layout='top-card']"
    assert_select "[data-testid='control-back']"
  end

  test "no-image demo lands on plain layout" do
    get "/demos/onboarding/no-image"
    follow_redirect!
    assert_select "[data-testid='onboarding-page'][data-layout='plain']"
  end

  test "button position demos keep continue available" do
    %w[buttons-left buttons-right buttons-full].each do |variant|
      get "/demos/onboarding/#{variant}"
      assert_response :redirect, "expected redirect for #{variant}, got #{status}"
      follow_redirect!
      assert_response :success, "expected run page for #{variant}, got #{status}"
      assert_select "[data-testid='control-advance']"
      assert_select "[data-testid='control-exit']", count: 0
    end
  end
end
