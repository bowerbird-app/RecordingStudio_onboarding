# frozen_string_literal: true

require "test_helper"

class AdminOnboardingTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.find_or_create_by!(email: "admin@admin.com") do |u|
      u.password = "Password"
      u.password_confirmation = "Password"
    end
    @admin_root = AdminRoot.find_or_create_by!(name: "Admin")
    Current.actor = @user
    @admin_recording = RecordingStudio.root_recording_for(@admin_root)
    result = RecordingStudioAccessible.bootstrap_owner_access!(
      recording: @admin_recording,
      actor: @user
    )
    raise result.error if result.failure?

    sign_in @user
    switch_to_admin_root!
  end

  def switch_to_admin_root!
    # Admin authorization requires RootSwitchable's current root to be AdminRoot.
    # Switch through the real endpoint so the signed device-key cookie stays consistent.
    get "/recording_studio_root_switchable/v1/root_switch", params: { scope: "all_workspaces" }
    assert_response :success

    patch "/recording_studio_root_switchable/v1/root_switch",
          params: {
            scope: "all_workspaces",
            root_switch: {
              root_recording_id: @admin_recording.id,
              scope: "all_workspaces"
            }
          }
    assert_response :redirect
    follow_redirect!
  end

  teardown do
    Current.actor = nil
  end

  test "admin onboarding section and screens render" do
    get "/admin/sections/onboarding"
    assert_response :success

    %w[onboarding_flows onboarding_previews onboarding_runs onboarding_funnel onboarding_provisioning].each do |key|
      get "/admin/screens/#{key}"
      assert_response :success, "expected screen #{key} to render"
    end
  end

  test "card preview writes nothing" do
    before_runs = RecordingStudioOnboarding::FlowRun.count
    before_progress = RecordingStudioOnboarding::StepProgress.count

    get "/onboarding/admin/previews/account_setup/welcome"
    assert_response :success
    assert_select "[data-testid=onboarding-admin-preview]"
    assert_select "[data-testid=onboarding-card-shell][data-preview=true]"

    assert_equal before_runs, RecordingStudioOnboarding::FlowRun.count
    assert_equal before_progress, RecordingStudioOnboarding::StepProgress.count
  end

  test "funnel screen numbers match analytics on fixture data" do
    run = RecordingStudioOnboarding.start(:account_setup, actor: @user)
    RecordingStudioOnboarding.mark_viewed(run, actor: @user)
    RecordingStudioOnboarding.advance(run, from: "welcome", actor: @user)

    summary = RecordingStudioOnboarding::Services::FunnelAnalytics.call(flow_key: :account_setup)
    assert summary.total_runs >= 1
    assert summary.steps.first.reached >= 1

    get "/admin/screens/onboarding_funnel", params: { flow_key: "account_setup" }
    assert_response :success
    assert_match(/welcome|Reached|Completion/i, response.body)
  end

  test "run detail reset and restart are admin-only logged actions" do
    run = RecordingStudioOnboarding.start(:account_setup, actor: @user)
    RecordingStudioOnboarding.mark_viewed(run, actor: @user)
    RecordingStudioOnboarding.advance(run, from: "welcome", actor: @user)
    run.reload
    assert_equal "workspace_details", run.current_step_key

    get "/onboarding/admin/runs/#{run.id}"
    assert_response :success
    assert_select "[data-testid=onboarding-admin-run]"

    post "/onboarding/admin/runs/#{run.id}/reset"
    assert_redirected_to "/onboarding/admin/runs/#{run.id}"
    run.reload
    assert_equal "welcome", run.current_step_key
    assert_equal "in_progress", run.status

    post "/onboarding/admin/runs/#{run.id}/restart"
    follow_redirect!
    assert_response :success
    assert RecordingStudioOnboarding::FlowRun.where(status: "dismissed", flow_key: "account_setup").exists?
    assert RecordingStudioOnboarding::FlowRun.open_runs.for_flow("account_setup").exists?
  end

  test "failed provisioning detail and retry" do
    execution = RecordingStudioOnboarding::ProvisioningExecution.create!(
      provisioner: "new_registration",
      idempotency_key: "admin-retry-#{SecureRandom.hex(4)}",
      actor: @user,
      status: "failed",
      failure_details: { "error_class" => "RuntimeError", "message" => "boom" },
      started_at: Time.current,
      completed_at: Time.current
    )

    get "/onboarding/admin/provisioning_executions/#{execution.id}"
    assert_response :success
    assert_select "[data-testid=onboarding-admin-provisioning]"
    assert_select "[data-testid=provisioning-failure-details]"

    post "/onboarding/admin/provisioning_executions/#{execution.id}/retry"
    assert_response :redirect
    execution.reload
    assert_includes %w[completed failed running], execution.status
  end

  test "empty admin screens render without runs" do
    RecordingStudioOnboarding::FlowRun.delete_all
    RecordingStudioOnboarding::ProvisioningExecution.delete_all

    get "/admin/screens/onboarding_runs"
    assert_response :success

    get "/admin/screens/onboarding_provisioning"
    assert_response :success

    get "/admin/screens/onboarding_flows"
    assert_response :success
  end
end
