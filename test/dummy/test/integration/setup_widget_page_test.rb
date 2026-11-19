# frozen_string_literal: true

require "test_helper"

class SetupWidgetPageTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.find_or_create_by!(email: "admin@admin.com") do |account|
      account.password = "Password123!"
      account.password_confirmation = "Password123!"
    end
    confirm_account!(@user)
    Workspace.find_or_create_by!(name: "Studio Workspace")
    RecordingStudioOnboarding::SetupCheck.where(actor: @user, checklist_key: "studio").delete_all
    accept_live_terms_for_tests!(@user)
    sign_in @user
  end

  test "the seeded admin sees the remaining studio items on the dashboard" do
    status = RecordingStudioOnboarding.setup_status(:studio, actor: @user)
    refute status.complete?

    get dashboard_path

    assert_response :success
    assert_select "title", text: "Recording Studio Onboarding", count: 1
    assert_select "h1", text: "Your studio", count: 0
    assert_select "h1, h2, h3, h4, h5, h6", count: 1
    assert_select "h2", text: "Finish your studio", count: 1
    refute_includes response.body, "Your studio"
    assert_select "[data-testid=onboarding-setup]"
    assert_select "[data-dashboard-row=setup] .fp-section-title.fp-on-backdrop", text: "Finish your studio"
    %w[h1 h2 h3 h4 h5 h6].each do |tag|
      assert_select "[data-testid=onboarding-setup] #{tag}", count: 0
    end
    assert_select "[data-testid=onboarding-setup] .fp-section-title", count: 0
    refute_includes response.body, "Here's what's left."
    assert_select "[data-testid=setup-item-profile] a[href=?]", "/", text: /Add your profile/
    assert_select "[data-testid=setup-item-press_kit] a[href=?]", "/flows", text: /Publish your first press kit/
    assert_select "[data-testid=setup-item-team] a[href=?]", "/flows", text: /Invite a teammate/
    assert_select "[data-testid=setup-item-email]", count: 0
    assert_select "[data-testid=setup-item-workspace]", count: 0
    status.remaining.each do |item|
      assert_select "[data-testid=setup-item-#{item.key}] a[href=?]", item.link, text: /#{Regexp.escape(item.next_step)}/
    end
    assert_select "a[href=?]", "/onboarding/setup/studio", text: /See your setup/
  end

  private

  def confirm_account!(account)
    return unless account.respond_to?(:skip_confirmation!)
    return if account.respond_to?(:confirmed?) && account.confirmed?

    account.skip_confirmation!
    account.save!
  end
end
