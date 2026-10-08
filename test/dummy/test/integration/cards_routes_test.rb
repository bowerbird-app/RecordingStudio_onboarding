# frozen_string_literal: true

require "test_helper"

class CardsRoutesTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @original = RecordingStudioOnboarding.instance_variable_get(:@configuration)
    RecordingStudioOnboarding.instance_variable_set(:@configuration, RecordingStudioOnboarding::Configuration.new)

    RecordingStudioOnboarding.configure do |config|
      config.current_actor = ->(controller) { controller.current_user }
      config.flow :account_setup do
        scope :user
        progress :segments
        dismissible true
        version 1
        after_complete "/"
        after_dismiss "/flows"
        step :welcome,
          component: "Dummy::Onboarding::WelcomeComponent",
          controls: %i[continue exit]
        step :workspace_details,
          component: "Dummy::Onboarding::WorkspaceDetailsComponent",
          controls: %i[back skip exit],
          skippable: true
        step :complete,
          component: "Dummy::Onboarding::CompleteComponent",
          controls: %i[continue],
          show_progress: false
      end

      config.flow :workspace_setup do
        scope :workspace
        progress :bar
        dismissible false
        version 1
        after_complete "/"
        after_dismiss "/"
        step :name_workspace,
          component: "Dummy::Onboarding::NameWorkspaceComponent",
          controls: %i[continue]
        step :invite_teammate,
          component: "Dummy::Onboarding::InviteTeammateComponent",
          controls: %i[back continue skip],
          skippable: true
      end
    end

    @user = User.create!(
      email: "cards-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @other = User.create!(
      email: "other-cards-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @workspace = create_owned_workspace(@user, "Card Workspace")
  end

  teardown do
    RecordingStudioOnboarding.instance_variable_set(:@configuration, @original)
  end

  test "full screen run shows card shell progress and controls" do
    sign_in @user
    run = RecordingStudioOnboarding.start(:account_setup, actor: @user)

    get recording_studio_onboarding.run_path(run)
    assert_response :success
    assert_select "[data-testid='onboarding-card-shell']"
    assert_select "[data-testid='card-welcome']"
    assert_select "[data-testid='onboarding-progress']"
    assert_select "[data-testid='onboarding-controls']"
    assert_select "[data-testid='control-advance']"
    assert_select "[data-testid='control-exit']"
    assert_select "[data-testid='control-back']", count: 0
  end

  test "advance back skip and dismiss through engine routes" do
    sign_in @user
    run = RecordingStudioOnboarding.start(:account_setup, actor: @user)

    post recording_studio_onboarding.advance_run_path(run), params: {from: "welcome"}
    assert_redirected_to recording_studio_onboarding.run_path(run)
    follow_redirect!
    assert_select "[data-testid='card-workspace-details']"
    assert_select "[data-testid='control-back']"
    assert_select "[data-testid='control-skip']"

    post recording_studio_onboarding.back_run_path(run), params: {from: "workspace_details"}
    follow_redirect!
    assert_select "[data-testid='card-welcome']"

    post recording_studio_onboarding.skip_run_path(run), params: {from: "welcome"}
    follow_redirect!
    assert_select "[data-testid='card-workspace-details']"

    post recording_studio_onboarding.dismiss_run_path(run)
    assert_redirected_to "/flows"
    assert_equal "dismissed", run.reload.status
  end

  test "form step validation error re-renders card with alert" do
    sign_in @user
    run = RecordingStudioOnboarding.start(:account_setup, actor: @user)
    RecordingStudioOnboarding.advance(run, from: :welcome, actor: @user)

    post onboarding_workspace_details_path, params: {
      run_id: run.id,
      from: "workspace_details",
      workspace: {name: ""}
    }
    assert_redirected_to recording_studio_onboarding.run_path(run)
    follow_redirect!
    assert_match(/Can.?t be blank|Couldn.?t save|blank/i, response.body)
  end

  test "form step success advances and completion exits to destination" do
    sign_in @user
    run = RecordingStudioOnboarding.start(:account_setup, actor: @user)
    RecordingStudioOnboarding.advance(run, from: :welcome, actor: @user)

    assert_difference -> { Workspace.count }, 1 do
      post onboarding_workspace_details_path, params: {
        run_id: run.id,
        from: "workspace_details",
        workspace: {name: "Formed Workspace"}
      }
    end
    assert_redirected_to recording_studio_onboarding.run_path(run)
    follow_redirect!
    assert_select "[data-testid='card-complete']"

    post recording_studio_onboarding.advance_run_path(run), params: {from: "complete"}
    assert_redirected_to "/"
    assert_equal "completed", run.reload.status
  end

  test "unauthorised actor receives 404" do
    run = RecordingStudioOnboarding.start(:account_setup, actor: @user)
    sign_in @other

    get recording_studio_onboarding.run_path(run)
    assert_response :not_found
  end

  test "custom authorize_run policy can deny with 404" do
    RecordingStudioOnboarding.configuration.authorize_run = ->(_run, _actor) { false }
    sign_in @user
    run = RecordingStudioOnboarding.start(:account_setup, actor: @user)

    get recording_studio_onboarding.run_path(run)
    assert_response :not_found
  end

  test "workspace scoped run authorises via accessible" do
    run = RecordingStudioOnboarding.start(:workspace_setup, actor: @user, subject: @workspace)
    sign_in @user
    get recording_studio_onboarding.run_path(run)
    assert_response :success
    assert_select "[data-testid='card-name-workspace']"
    assert_select "[data-testid='onboarding-progress'][data-mode='bar']"

    sign_in @other
    get recording_studio_onboarding.run_path(run)
    assert_response :not_found
  end

  test "non-dismissible exit leaves run in progress and redirects" do
    sign_in @user
    run = RecordingStudioOnboarding.start(:workspace_setup, actor: @user, subject: @workspace)

    post recording_studio_onboarding.dismiss_run_path(run)
    assert_redirected_to "/"
    assert_equal "in_progress", run.reload.status
  end

  test "embedded run component renders on flows index" do
    sign_in @user
    RecordingStudioOnboarding.start(:account_setup, actor: @user)

    get flows_path
    assert_response :success
    assert_select "[data-testid='embedded-run']"
    assert_select "[data-testid='onboarding-run']"
    assert_select "[data-testid='card-welcome']"
  end

  test "stale from is a no-op re-render" do
    sign_in @user
    run = RecordingStudioOnboarding.start(:account_setup, actor: @user)
    RecordingStudioOnboarding.advance(run, from: :welcome, actor: @user)

    post recording_studio_onboarding.advance_run_path(run), params: {from: "welcome"}
    follow_redirect!
    assert_equal "workspace_details", run.reload.current_step_key
    assert_select "[data-testid='card-workspace-details']"
  end

  private

  def create_owned_workspace(user, name)
    workspace = Workspace.create!(name: name)
    recording = RecordingStudio.root_recording_for(workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: recording, actor: user)
    raise result.error if result.failure?

    workspace
  end
end
