# frozen_string_literal: true

require "test_helper"

class FlowsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @original_configuration = RecordingStudioOnboarding.configuration
    RecordingStudioOnboarding.reset_for_tests!
    RecordingStudioOnboarding.configure do |config|
      config.flow :account_setup do
        scope :user
        progress :bar
        dismissible true
        version 1
        step :welcome,
          component: "Dummy::Onboarding::WelcomeComponent",
          controls: %i[continue],
          skippable: true
        step :details,
          component: "Dummy::Onboarding::WorkspaceDetailsComponent",
          controls: %i[continue],
          skippable: true
        step :finish,
          component: "Dummy::Onboarding::CompleteComponent",
          controls: %i[continue],
          show_progress: false,
          skippable: false
      end

      config.flow :workspace_setup do
        scope :workspace
        progress :bar
        dismissible false
        version 1
        step :name, component: "Dummy::Onboarding::NameWorkspaceComponent"
        step :invite, component: "Dummy::Onboarding::InviteTeammateComponent", skippable: true
      end

      config.flow :first_presskit do
        scope :subject
        progress :bar
        dismissible true
        version 1
        step :intro, component: "Dummy::Onboarding::PresskitIntroductionComponent"
        step :publish, component: "Dummy::Onboarding::PublishComponent"
      end
    end

    @user = User.create!(
      email: "flow-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @other = User.create!(
      email: "other-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @workspace = create_owned_workspace(@user, "Flow Workspace")
    @page = create_page_under(@workspace, title: "Press kit draft")
    accept_live_terms_for_tests!(@user)
    accept_live_terms_for_tests!(@other)
  end

  teardown do
    RecordingStudioOnboarding.reset_for_tests!(configuration: @original_configuration)
  end

  test "start returns the same open run for the same user scope" do
    first = RecordingStudioOnboarding.start(:account_setup, actor: @user)
    second = RecordingStudioOnboarding.start(:account_setup, actor: @user)

    assert_equal first.id, second.id
    assert_equal "in_progress", first.status
    assert_equal @user, first.scope
    assert_equal @user, first.initiating_actor
    assert_equal 3, first.step_progresses.count
  end

  test "workspace and subject uniqueness exclude initiating actor" do
    grant_view(@other, @workspace)

    run_a = RecordingStudioOnboarding.start(:workspace_setup, actor: @user, subject: @workspace)
    run_b = RecordingStudioOnboarding.start(:workspace_setup, actor: @other, subject: @workspace)
    assert_equal run_a.id, run_b.id
    assert_equal @user, run_a.initiating_actor

    page_run_a = RecordingStudioOnboarding.start(:first_presskit, actor: @user, subject: @page)
    page_run_b = RecordingStudioOnboarding.start(:first_presskit, actor: @other, subject: @page)
    assert_equal page_run_a.id, page_run_b.id
    assert_equal @page, page_run_a.scope
  end

  test "start and active_run deny actors without Accessible view on the subject" do
    assert_raises(RecordingStudioOnboarding::Unauthorized) do
      RecordingStudioOnboarding.start(:workspace_setup, actor: @other, subject: @workspace)
    end
    assert_nil RecordingStudioOnboarding.active_run(:workspace_setup, actor: @other, subject: @workspace)

    RecordingStudioOnboarding.start(:workspace_setup, actor: @user, subject: @workspace)
    assert_nil RecordingStudioOnboarding.active_run(:workspace_setup, actor: @other, subject: @workspace)

    assert_raises(RecordingStudioOnboarding::Unauthorized) do
      RecordingStudioOnboarding.start(:first_presskit, actor: @other, subject: @page)
    end
  end

  test "flows index filters pages in SQL before ordering so extra pages do not explode queries" do
    sign_in @user
    get flows_path
    assert_response :success
    baseline = count_select_queries { get flows_path }

    stranger_workspace = create_owned_workspace(@other, "Stranger Pages")
    20.times do |index|
      create_page_under(stranger_workspace, title: "Extra #{index}", actor: @other)
    end
    20.times do |index|
      create_page_under(@workspace, title: "Own extra #{index}", actor: @user)
    end

    scaled = count_select_queries { get flows_path }
    assert_response :success
    assert_operator scaled - baseline, :<, 20,
                    "expected extra pages not to add per-page authorized? SQL (#{baseline} -> #{scaled})"
  end

  test "flow launcher 404s when the workspace or page is not Accessible" do
    sign_in @other
    get flows_path
    assert_response :success

    post start_flows_path, params: {
      flow_key: "workspace_setup",
      scope_type: "Workspace",
      scope_id: @workspace.id
    }
    assert_response :not_found

    post start_flows_path, params: {
      flow_key: "first_presskit",
      scope_type: "Page",
      scope_id: @page.id
    }
    assert_response :not_found

    sign_in @user
    post start_flows_path, params: {
      flow_key: "workspace_setup",
      scope_type: "Workspace",
      scope_id: @workspace.id
    }
    assert_response :redirect
  end

  test "completed and dismissed runs do not restart; explicit reset works" do
    run = RecordingStudioOnboarding.start(:account_setup, actor: @user)
    RecordingStudioOnboarding.advance(run, from: :welcome, actor: @user)
    RecordingStudioOnboarding.advance(run, from: :details, actor: @user)
    RecordingStudioOnboarding.advance(run, from: :finish, actor: @user)
    run.reload
    assert_equal "completed", run.status

    assert_nil RecordingStudioOnboarding.active_run(:account_setup, actor: @user)
    restarted = RecordingStudioOnboarding.start(:account_setup, actor: @user)
    refute_equal run.id, restarted.id

    RecordingStudioOnboarding.dismiss(restarted, actor: @user)
    restarted.reload
    assert_equal "dismissed", restarted.status
    assert_nil RecordingStudioOnboarding.active_run(:account_setup, actor: @user)

    reset = RecordingStudioOnboarding.reset(restarted, actor: @user)
    assert_equal "in_progress", reset.status
    assert_equal "welcome", reset.current_step_key
    assert_nil reset.completed_at
    assert_nil reset.dismissed_at
  end

  test "transitions advance back skip dismiss and from mismatch is a no-op" do
    run = RecordingStudioOnboarding.start(:account_setup, actor: @user)
    RecordingStudioOnboarding.mark_viewed(run, actor: @user)

    RecordingStudioOnboarding.advance(run, from: :welcome, actor: @user)
    run.reload
    assert_equal "details", run.current_step_key
    assert_equal "completed", run.step_progresses.find_by!(step_key: "welcome").status

    RecordingStudioOnboarding.advance(run, from: :welcome, actor: @user)
    run.reload
    assert_equal "details", run.current_step_key

    RecordingStudioOnboarding.back(run, from: :details, actor: @user)
    run.reload
    assert_equal "welcome", run.current_step_key

    RecordingStudioOnboarding.skip(run, from: :welcome, actor: @user)
    run.reload
    assert_equal "details", run.current_step_key
    assert_equal "skipped", run.step_progresses.find_by!(step_key: "welcome").status

    RecordingStudioOnboarding.advance(run, from: :details, actor: @user)
    run.reload
    assert_equal "finish", run.current_step_key

    assert_raises(ArgumentError) do
      RecordingStudioOnboarding.skip(run, from: :finish, actor: @user)
    end

    RecordingStudioOnboarding.dismiss(run, actor: @user)
    run.reload
    assert_equal "dismissed", run.status
  end

  test "concurrent start shares one open run" do
    runs = ConcurrentArray.new
    threads = 2.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          runs << RecordingStudioOnboarding.start(:account_setup, actor: @user)
        end
      end
    end
    threads.each(&:join)

    assert_equal 1, RecordingStudioOnboarding::FlowRun.where(flow_key: "account_setup", scope: @user).count
    assert_equal 1, runs.map(&:id).uniq.size
  end

  test "concurrent advancement on a shared workspace run" do
    run = RecordingStudioOnboarding.start(:workspace_setup, actor: @user, subject: @workspace)
    barrier = ConcurrentBarrier.new(2)

    threads = 2.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          barrier.wait
          RecordingStudioOnboarding.advance(run, from: :name, actor: @user)
        end
      end
    end
    threads.each(&:join)

    run.reload
    assert_equal "invite", run.current_step_key
    assert_equal "completed", run.step_progresses.find_by!(step_key: "name").status
  end

  test "definition version changes add and remove steps without reopening completed runs" do
    run = RecordingStudioOnboarding.start(:account_setup, actor: @user)
    RecordingStudioOnboarding.advance(run, from: :welcome, actor: @user)
    run.reload
    assert_equal "details", run.current_step_key

    RecordingStudioOnboarding.reset_for_tests!
    RecordingStudioOnboarding.configure do |config|
      config.flow :account_setup do
        scope :user
        version 2
        step :welcome, component: "Dummy::Onboarding::WelcomeComponent"
        step :extra, component: "Dummy::Onboarding::InviteTeammateComponent"
        step :finish, component: "Dummy::Onboarding::CompleteComponent"
      end
    end

    reconciled = RecordingStudioOnboarding.active_run(:account_setup, actor: @user)
    assert_equal run.id, reconciled.id
    # current step "details" was removed → move to first incomplete remaining step
    assert_equal "extra", reconciled.current_step_key
    assert RecordingStudioOnboarding::StepProgress.exists?(flow_run: run, step_key: "extra")

    while run.reload.open?
      RecordingStudioOnboarding.advance(run, from: run.current_step_key.to_sym, actor: @user)
    end
    assert_equal "completed", run.status

    RecordingStudioOnboarding.reset_for_tests!
    RecordingStudioOnboarding.configure do |config|
      config.flow :account_setup do
        scope :user
        version 3
        step :brand_new, component: "Dummy::Onboarding::WelcomeComponent"
      end
    end

    still_completed = RecordingStudioOnboarding::FlowRun.find(run.id)
    RecordingStudioOnboarding::Services::ReconcileRun.call(still_completed)
    still_completed.reload
    assert_equal "completed", still_completed.status
  end

  test "flow events emit expected payloads" do
    events = []
    subscriber = ActiveSupport::Notifications.subscribe(/recording_studio_onboarding/) do |name, *_args, payload|
      events << [name, payload]
    end

    run = RecordingStudioOnboarding.start(:account_setup, actor: @user)
    RecordingStudioOnboarding.mark_viewed(run, actor: @user)
    RecordingStudioOnboarding.advance(run, from: :welcome, actor: @user)
    RecordingStudioOnboarding.skip(run, from: :details, actor: @user)
    RecordingStudioOnboarding.advance(run, from: :finish, actor: @user)

    names = events.map(&:first)
    assert_includes names, "flow.started.recording_studio_onboarding"
    assert_includes names, "step.viewed.recording_studio_onboarding"
    assert_includes names, "step.completed.recording_studio_onboarding"
    assert_includes names, "step.skipped.recording_studio_onboarding"
    assert_includes names, "flow.completed.recording_studio_onboarding"

    started = events.find { |name, _| name.start_with?("flow.started") }.last
    assert_equal run.id, started[:run_uuid]
    assert_equal "account_setup", started[:flow_key]
    assert_equal @user.id, started[:actor_id]
    refute started.key?(:password)

    RecordingStudioOnboarding.reset(run, actor: @user)
    assert events.any? { |name, _| name.start_with?("flow.reset") }

    RecordingStudioOnboarding.dismiss(run.reload, actor: @user)
    assert events.any? { |name, _| name.start_with?("flow.dismissed") }
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end

  test "flows index and run show pages render" do
    sign_in @user
    run = RecordingStudioOnboarding.start(:account_setup, actor: @user)

    get flows_path
    assert_response :success
    assert_match(/Onboarding flows/, response.body)
    assert_match(/account_setup/, response.body)
    assert_select "[data-testid='registered-flows']"

    get recording_studio_onboarding.run_path(run)
    assert_response :success
    assert_match(/welcome|Welcome/i, response.body)
    assert_select "[data-testid='onboarding-card-shell']"
    assert_select "[data-testid='onboarding-controls']"
  end

  test "non-dismissible workspace flow leaves status open on dismiss" do
    run = RecordingStudioOnboarding.start(:workspace_setup, actor: @user, subject: @workspace)
    RecordingStudioOnboarding.dismiss(run, actor: @user)
    run.reload
    assert_equal "in_progress", run.status
    assert_nil run.dismissed_at
  end

  private

  def create_owned_workspace(user, name)
    workspace = Workspace.create!(name: name)
    grant_owner(user, workspace)
    workspace
  end

  def create_page_under(workspace, title:, actor: @user)
    page = Page.create!(title: title)
    with_actor(actor) do
      root = RecordingStudio.root_recording_for(workspace)
      RecordingStudio.record!(
        action: "created",
        recordable: page,
        root_recording: root,
        parent_recording: root,
        actor: actor
      )
    end
    page
  end

  def grant_owner(user, workspace)
    with_actor(user) do
      recording = RecordingStudio.root_recording_for(workspace)
      result = RecordingStudioAccessible.bootstrap_owner_access!(recording: recording, actor: user)
      raise result.error if result.failure?
    end
  end

  def count_select_queries
    count = 0
    callback = lambda do |_name, _start, _finish, _id, payload|
      sql = payload[:sql].to_s
      next unless sql.match?(/\A\s*SELECT/i)
      next if payload[:cached]
      next if payload[:name].to_s == "SCHEMA"

      count += 1
    end
    # Executor QueryCache re-enables caching inside `get`, so connection.uncached
    # around the request does not stick. Clear the thread caches before each
    # count so baseline and post-write GETs both start cold.
    ActiveRecord::Base.clear_query_caches_for_current_thread
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { yield }
    count
  end

  def grant_view(user, workspace)
    with_actor(@user) do
      recording = RecordingStudio.root_recording_for(workspace)
      result = RecordingStudioAccessible.grant_access(
        recording: recording,
        actor: user,
        role: :view,
        manager_actor: @user
      )
      raise result.error if result.failure?
    end
  end

  # Tiny helpers so concurrency tests do not need extra gems.
  class ConcurrentArray
    def initialize
      @mutex = Mutex.new
      @items = []
    end

    def <<(value)
      @mutex.synchronize { @items << value }
    end

    def map(&)
      @mutex.synchronize { @items.map(&) }
    end
  end

  class ConcurrentBarrier
    def initialize(count)
      @count = count
      @mutex = Mutex.new
      @cv = ConditionVariable.new
      @waiting = 0
    end

    def wait
      @mutex.synchronize do
        @waiting += 1
        if @waiting >= @count
          @cv.broadcast
        else
          @cv.wait(@mutex)
        end
      end
    end
  end
end
