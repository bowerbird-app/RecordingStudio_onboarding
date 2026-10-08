# frozen_string_literal: true

require "test_helper"

class FlowsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @original_configuration = RecordingStudioOnboarding.instance_variable_get(:@configuration)
    RecordingStudioOnboarding.instance_variable_set(:@configuration, RecordingStudioOnboarding::Configuration.new)
    RecordingStudioOnboarding.configure do |config|
      config.flow :account_setup do
        scope :user
        progress :segments
        dismissible true
        version 1
        step :welcome, component: "Dummy::Welcome", controls: %i[continue exit]
        step :details, component: "Dummy::Details", controls: %i[back continue skip], skippable: true
        step :finish, component: "Dummy::Finish", controls: %i[continue], show_progress: false, skippable: false
      end

      config.flow :workspace_setup do
        scope :workspace
        progress :bar
        dismissible false
        version 1
        step :name, component: "Dummy::Name"
        step :invite, component: "Dummy::Invite", skippable: true
      end

      config.flow :first_presskit do
        scope :subject
        progress :segments
        dismissible true
        version 1
        step :intro, component: "Dummy::Intro"
        step :publish, component: "Dummy::Publish"
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
    @page = Page.create!(title: "Press kit draft")
  end

  teardown do
    RecordingStudioOnboarding.instance_variable_set(:@configuration, @original_configuration)
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
    run_a = RecordingStudioOnboarding.start(:workspace_setup, actor: @user, subject: @workspace)
    run_b = RecordingStudioOnboarding.start(:workspace_setup, actor: @other, subject: @workspace)
    assert_equal run_a.id, run_b.id
    assert_equal @user, run_a.initiating_actor

    page_run_a = RecordingStudioOnboarding.start(:first_presskit, actor: @user, subject: @page)
    page_run_b = RecordingStudioOnboarding.start(:first_presskit, actor: @other, subject: @page)
    assert_equal page_run_a.id, page_run_b.id
    assert_equal @page, page_run_a.scope
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

    RecordingStudioOnboarding.instance_variable_set(:@configuration, RecordingStudioOnboarding::Configuration.new)
    RecordingStudioOnboarding.configure do |config|
      config.flow :account_setup do
        scope :user
        version 2
        step :welcome, component: "Dummy::Welcome"
        step :extra, component: "Dummy::Extra"
        step :finish, component: "Dummy::Finish"
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

    RecordingStudioOnboarding.instance_variable_set(:@configuration, RecordingStudioOnboarding::Configuration.new)
    RecordingStudioOnboarding.configure do |config|
      config.flow :account_setup do
        scope :user
        version 3
        step :brand_new, component: "Dummy::BrandNew"
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

    get flow_run_path(run)
    assert_response :success
    assert_match(/welcome/, response.body)
    assert_select "[data-testid='step-progress-list']"
    assert_select "[data-testid='run-controls']"
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
    recording = RecordingStudio.root_recording_for(workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: recording, actor: user)
    raise result.error if result.failure?

    workspace
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
