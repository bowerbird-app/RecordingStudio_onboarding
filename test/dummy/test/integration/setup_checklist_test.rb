# frozen_string_literal: true

require "test_helper"

class SetupChecklistIntegrationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @original = RecordingStudioOnboarding.configuration
    RecordingStudioOnboarding.reset_for_tests!
    @user = create_user("setup")
    @other = create_user("other")
    @workspace = create_owned_workspace(@user, "Setup Workspace")
    accept_live_terms_for_tests!(@user)
    accept_live_terms_for_tests!(@other)
    clear_enqueued_jobs
  end

  teardown do
    RecordingStudioOnboarding.reset_for_tests!(configuration: @original)
  end

  test "setup status computes then returns the saved answer and enqueues a stale recheck" do
    done = true
    register_box(->(*) { done })

    first = RecordingStudioOnboarding.setup_status(:box, actor: @user)
    assert first.complete?
    assert_equal "Add a name", first.done.first.next_step
    assert_equal 1, RecordingStudioOnboarding::SetupCheck.count

    done = false
    assert_no_enqueued_jobs only: RecordingStudioOnboarding::RecheckSetupJob do
      cached = RecordingStudioOnboarding.setup_status(:box, actor: @user)
      assert cached.complete?
      assert_equal :name, cached.done.first.key
    end

    events = []
    callback = ->(*args) { events << args.last }
    travel 6.minutes do
      ActiveSupport::Notifications.subscribed(callback, "setup.regressed.recording_studio_onboarding") do
        assert_enqueued_jobs 1, only: RecordingStudioOnboarding::RecheckSetupJob do
          assert RecordingStudioOnboarding.setup_status(:box, actor: @user).complete?
        end
        perform_enqueued_jobs
      end
      refute RecordingStudioOnboarding.setup_status(:box, actor: @user).complete?
    end
    assert_equal false, events.last[:complete]
    assert_equal "box", events.last[:checklist_key]
  end

  test "a fresh saved check is not rechecked again inside the interval" do
    register_box(->(*) { false })
    RecordingStudioOnboarding.configuration.setup_recheck_interval = 10.minutes
    RecordingStudioOnboarding.setup_status(:box, actor: @user)

    travel 3.minutes do
      assert_no_enqueued_jobs only: RecordingStudioOnboarding::RecheckSetupJob do
        RecordingStudioOnboarding.setup_status(:box, actor: @user)
      end
    end
  end

  test "completing a checklist emits setup.completed" do
    register_box(->(*) { true })
    events = []
    callback = ->(*args) { events << args.last }
    ActiveSupport::Notifications.subscribed(callback, "setup.completed.recording_studio_onboarding") do
      status = RecordingStudioOnboarding.setup_status(:box, actor: @user)
      assert status.complete?
    end
    assert_equal true, events.last[:complete]
  end

  test "sign in enqueues a recheck for a person checklist" do
    register_box(->(*) { false })
    assert_enqueued_with(job: RecordingStudioOnboarding::RecheckSetupJob) do
      sign_in @user
      get root_path
    end
  end

  test "your setup page renders live status for the signed in person" do
    register_box(->(*) { false })
    sign_in @user
    get recording_studio_onboarding.setup_path("box")

    assert_response :success
    assert_select "title", text: "Your setup", count: 1
    assert_select "meta[property='og:title'][content=?]", "Your setup"
    assert_select "h1", text: "Your setup", count: 1
    assert_includes response.body, "What to do next."
    assert_setup_in_first_column do |grid|
      assert_select grid, "h1", text: "Your setup", count: 1
      assert_select grid, "[data-testid=setup-remaining].flat-pack-list-divided" do
        assert_select "[data-testid=setup-item-name] a[href=?]", "https://example.com/name", text: /Add a name/
        assert_select "[data-testid=setup-item-name][class*='hover:bg-']"
        assert_select "[data-flat-pack--icon-name-value=chevron-right]"
      end
    end
    assert_select "[data-testid=setup-done]", count: 0
    refute_includes response.body, ">Open<"
    row = RecordingStudioOnboarding::SetupCheck.find_by!(checklist_key: "box", actor: @user)
    refute row.complete?
  end

  test "your setup page shows the all-done line when nothing remains" do
    register_box(->(*) { true })
    sign_in @user
    get recording_studio_onboarding.setup_path("box")

    assert_response :success
    assert_select "title", text: "Your setup", count: 1
    assert_includes response.body, "Nothing left. Nice work."
    assert_includes response.body, "You&#39;re all set."
    assert_setup_in_first_column do |grid|
      assert_select grid, "h1", text: "Your setup", count: 1
      assert_select grid, "p", text: "Nothing left. Nice work."
    end
  end

  test "your setup page uses the checklist title and the subtitle for that state" do
    register_titled_checklist(:box, check: ->(*) { false })
    register_titled_checklist(:finished, check: ->(*) { true })
    register_titled_checklist(:hidden, applies: ->(*) { false }, check: ->(*) { false })
    sign_in @user

    get recording_studio_onboarding.setup_path("box")
    assert_response :success
    assert_select "title", text: "Finish your studio", count: 1
    assert_select "meta[property='og:title'][content=?]", "Finish your studio"
    assert_select "h1", count: 1
    assert_includes response.body, "Here&#39;s what&#39;s left."
    assert_setup_in_first_column do |grid|
      assert_select grid, "h1", text: "Finish your studio", count: 1
    end

    get recording_studio_onboarding.setup_path("finished")
    assert_response :success
    assert_select "title", text: "Finish your studio", count: 1
    assert_includes response.body, "The studio is ready."
    assert_includes response.body, "Nothing left. Nice work."

    get recording_studio_onboarding.setup_path("hidden")
    assert_response :success
    assert_select "title", text: "Finish your studio", count: 1
    assert_select "h1", count: 1
    assert_includes response.body, "This list isn&#39;t for you."
  end

  test "a raising check stays on the page as not done" do
    RecordingStudioOnboarding.configure do |config|
      config.checklist :boom do
        scope :user
        item :explode,
          check: ->(*) { raise "nope" },
          next_step: "Try that step again",
          link: "https://example.com/try"
      end
    end
    sign_in @user
    get recording_studio_onboarding.setup_path("boom")

    assert_response :success
    assert_includes response.body, "Try that step again"
  end

  test "setup page auth follows the signed in person and workspace access" do
    register_workspace_checklist
    get recording_studio_onboarding.setup_path("box")
    assert_response :redirect

    sign_in @user
    get recording_studio_onboarding.setup_path("missing")
    assert_response :not_found

    get recording_studio_onboarding.setup_path("workspace_ready")
    assert_response :not_found

    get recording_studio_onboarding.setup_path(
      "workspace_ready",
      subject_type: "Workspace",
      subject_id: @workspace.id
    )
    assert_response :success
    assert_includes response.body, "Nothing left. Nice work."

    sign_in @other
    get recording_studio_onboarding.setup_path(
      "workspace_ready",
      subject_type: "Workspace",
      subject_id: @workspace.id
    )
    assert_response :not_found

    assert_raises(RecordingStudioOnboarding::Unauthorized) do
      RecordingStudioOnboarding.setup_status(:workspace_ready, actor: @other, subject: @workspace)
    end
  end

  test "two checklists keep separate saved rows" do
    register_box(->(*) { true })
    RecordingStudioOnboarding.configure do |config|
      config.checklist :billing do
        scope :user
        item :card, check: ->(*) { false }, next_step: "Add a card", link: "https://example.com/card"
      end
    end

    box = RecordingStudioOnboarding.setup_status(:box, actor: @user)
    billing = RecordingStudioOnboarding.setup_status(:billing, actor: @user)

    assert box.complete?
    refute billing.complete?
    assert_equal 2, RecordingStudioOnboarding::SetupCheck.where(actor: @user).count
  end

  private

  def assert_setup_in_first_column
    grid = css_select("div.grid").find { |node| node["class"].to_s.split.include?("md:grid-cols-2") }
    assert grid, "expected the setup page to use a two-column grid"
    classes = grid["class"].to_s.split
    assert_includes classes, "grid-cols-1"
    assert_equal 1, css_select(grid, ".fp-grid__item").size
    yield grid
  end

  def register_titled_checklist(name, check:, applies: nil)
    RecordingStudioOnboarding.configure do |config|
      config.checklist name do
        scope :user
        applies_to applies if applies
        title "Finish your studio"
        subtitle remaining: "Here's what's left.",
                 complete: "The studio is ready.",
                 not_applicable: "This list isn't for you."
        item :name, check: check, next_step: "Add a name", link: "https://example.com/name"
      end
    end
  end

  def register_box(check)
    RecordingStudioOnboarding.configure do |config|
      config.checklist :box do
        scope :user
        item :name, check: check, next_step: "Add a name", link: "https://example.com/name"
      end
    end
  end

  def register_workspace_checklist
    RecordingStudioOnboarding.configure do |config|
      config.checklist :workspace_ready do
        scope :workspace
        item :named,
          check: ->(_actor, workspace) { workspace.name.present? },
          next_step: "Give the workspace a name",
          link: "https://example.com/workspace"
      end
    end
  end

  def create_user(prefix)
    User.create!(
      email: "#{prefix}-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
  end

  def create_owned_workspace(user, name)
    workspace = Workspace.create!(name: name)
    with_actor(user) do
      recording = RecordingStudio.create_root_recording!(workspace, actor: user)
      result = RecordingStudioAccessible.bootstrap_owner_access!(recording: recording, actor: user)
      raise result.error if result.failure?
    end
    workspace
  end
end
