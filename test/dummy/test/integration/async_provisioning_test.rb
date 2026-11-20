# frozen_string_literal: true

require "test_helper"
require "timeout"

class AsyncProvisioningTest < ActionDispatch::IntegrationTest
  EVENT = RecordingStudioOnboarding::UsersRegistrationIntegration::EVENT

  setup do
    @configuration = RecordingStudioOnboarding.configuration
    @previous_async = @configuration.provision_async
    @previous_registration = @configuration.provisioner_for(:new_registration)
  end

  teardown do
    @configuration.provision_async = @previous_async
    @configuration.provision(:new_registration, with: @previous_registration) if @previous_registration
  end

  test "default sync provisioning completes when the handler returns" do
    refute @configuration.provision_async?

    user = create_user!("sync")
    seen = nil
    handler = lambda do |actor:, subject: nil, root: nil, context: {}|
      seen = { actor_id: actor.id, subject: subject, root: root, context: context }
      :ok
    end
    @configuration.provision(:sync_handoff, with: handler)

    execution = RecordingStudioOnboarding.provision(:sync_handoff, actor: user, context: { source: "test" })

    assert_equal "completed", execution.status
    assert_equal user.id, seen[:actor_id]
    assert_equal({ source: "test" }, seen[:context])
    assert_nil execution.failure_details
    assert execution.completed_at
  end

  test "async provisioning stays pending until complete_provisioning!" do
    user = create_user!("async")
    received = nil
    @configuration.provision_async = true
    @configuration.provision(:async_handoff, with: lambda do |actor:, execution:, **|
      received = { actor_id: actor.id, execution: execution }
      :enqueued
    end)

    execution = RecordingStudioOnboarding.provision(:async_handoff, actor: user)

    assert_equal "pending", execution.status
    assert_nil execution.completed_at
    assert_nil execution.failure_details
    assert_equal user.id, received[:actor_id]
    assert_equal execution.id, received[:execution].id

    completed = RecordingStudioOnboarding.complete_provisioning!(execution.id)
    assert_equal "completed", completed.status
    assert_equal execution.id, completed.id
    assert completed.completed_at
    assert_nil completed.failure_details

    again = RecordingStudioOnboarding.complete_provisioning!(execution)
    assert_equal "completed", again.status
    assert_equal completed.completed_at, again.completed_at
  end

  test "an async handler that already completed the execution keeps that outcome" do
    user = create_user!("inline")
    @configuration.provision_async = true
    @configuration.provision(:inline_handoff, with: lambda do |execution:, **|
      RecordingStudioOnboarding.complete_provisioning!(execution)
      :done
    end)

    execution = RecordingStudioOnboarding.provision(:inline_handoff, actor: user)

    assert_equal "completed", execution.reload.status
  end

  test "fail_provisioning! records the failed state and the error" do
    user = create_user!("fail")
    @configuration.provision_async = true
    @configuration.provision(:async_fail, with: ->(**) { :enqueued })

    execution = RecordingStudioOnboarding.provision(:async_fail, actor: user)
    error = RuntimeError.new("workspace missing password=secret-value")

    failed = RecordingStudioOnboarding.fail_provisioning!(execution.id, error: error)

    assert_equal "failed", failed.status
    assert_equal execution.id, failed.id
    assert failed.completed_at
    assert_includes failed.failure_details, "RuntimeError"
    assert_includes failed.failure_details, "password=[FILTERED]"
    refute_includes failed.failure_details, "secret-value"

    assert_raises(ArgumentError) do
      RecordingStudioOnboarding.fail_provisioning!(execution, error: "nope")
    end
    assert_equal "failed", execution.reload.status

    recovered = RecordingStudioOnboarding.complete_provisioning!(execution)
    assert_equal "completed", recovered.status
    assert_nil recovered.failure_details
  end

  test "fail_provisioning! does not overwrite a completed execution" do
    user = create_user!("late-fail")
    @configuration.provision_async = true
    @configuration.provision(:async_late_fail, with: ->(**) { :enqueued })

    execution = RecordingStudioOnboarding.provision(:async_late_fail, actor: user)
    RecordingStudioOnboarding.complete_provisioning!(execution)

    assert_raises(ArgumentError) do
      RecordingStudioOnboarding.fail_provisioning!(execution.id, error: RuntimeError.new("late"))
    end
    assert_equal "completed", execution.reload.status
    assert_nil execution.failure_details
  end

  test "replaying registration.completed retries pending and failed executions" do
    calls = []
    @configuration.provision_async = true
    @configuration.provision(:new_registration, with: lambda do |execution:, **|
      calls << execution.id
      :enqueued
    end)

    user = create_user!("event")
    emit_registration!(user)
    execution = execution_for(user)
    assert_equal "pending", execution.status
    assert_equal [execution.id], calls

    emit_registration!(user)
    assert_equal "pending", execution.reload.status
    assert_equal [execution.id, execution.id], calls

    RecordingStudioOnboarding.complete_provisioning!(execution)
    emit_registration!(user)
    assert_equal "completed", execution.reload.status
    assert_equal [execution.id, execution.id], calls

    failed_user = create_user!("event-failed")
    emit_registration!(failed_user)
    failed = execution_for(failed_user)
    RecordingStudioOnboarding.fail_provisioning!(failed, error: RuntimeError.new("job gave up"))
    assert_equal "failed", failed.reload.status
    assert_includes failed.failure_details, "job gave up"

    emit_registration!(failed_user)
    assert_equal "pending", failed.reload.status
    assert_nil failed.failure_details
    assert_equal 4, calls.size
  end

  test "replaying provision retries pending and failed executions and skips completed ones" do
    calls = []
    @configuration.provision_async = true
    @configuration.provision(:replay_handoff, with: lambda do |**|
      calls << :ran
      :enqueued
    end)
    user = create_user!("replay")

    pending = RecordingStudioOnboarding.provision(:replay_handoff, actor: user)
    assert_equal "pending", pending.status
    assert_equal 1, calls.size

    again = RecordingStudioOnboarding.provision(:replay_handoff, actor: user)
    assert_equal pending.id, again.id
    assert_equal "pending", again.status
    assert_equal 2, calls.size

    RecordingStudioOnboarding.fail_provisioning!(pending, error: RuntimeError.new("queue lost the job"))
    retried = RecordingStudioOnboarding.provision(:replay_handoff, actor: user)
    assert_equal pending.id, retried.id
    assert_equal "pending", retried.status
    assert_nil retried.failure_details
    assert_equal 3, calls.size

    RecordingStudioOnboarding.complete_provisioning!(retried)
    finished = RecordingStudioOnboarding.provision(:replay_handoff, actor: user)
    assert_equal pending.id, finished.id
    assert_equal "completed", finished.status
    assert_equal 3, calls.size
  end

  test "a running async provision is not started twice" do
    user = create_user!("running")
    entered = Queue.new
    release = Queue.new
    calls = 0
    mutex = Mutex.new
    @configuration.provision_async = true
    @configuration.provision(:running_handoff, with: lambda do |**|
      mutex.synchronize { calls += 1 }
      entered << true
      release.pop
      :enqueued
    end)

    first = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        RecordingStudioOnboarding.provision(:running_handoff, actor: user)
      end
    end
    Timeout.timeout(5) { entered.pop }

    second = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        RecordingStudioOnboarding.provision(:running_handoff, actor: user)
      end
    end
    assert_thread_finished(second)
    assert_equal 1, mutex.synchronize { calls }

    release << true
    assert_thread_finished(first)

    execution = RecordingStudioOnboarding::ProvisioningExecution.find_by!(
      provisioner: "running_handoff",
      actor: user
    )
    assert_equal "pending", execution.status
    assert_equal 1, mutex.synchronize { calls }
  ensure
    if defined?(release) && release && defined?(first) && first&.alive?
      release << true
    end
    first.join if defined?(first) && first
    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        RecordingStudioOnboarding::ProvisioningExecution.where(provisioner: "running_handoff").delete_all
      end
    end.join
  end

  private

  def create_user!(label)
    User.create!(
      email: "#{label}-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
  end

  def emit_registration!(user)
    ActiveSupport::Notifications.instrument(EVENT, user_id: user.id, method: :password)
  end

  def assert_thread_finished(thread)
    thread.join
    return if thread.status == false

    flunk "provision thread failed"
  end

  def execution_for(user)
    RecordingStudioOnboarding::ProvisioningExecution.find_by!(
      provisioner: "new_registration",
      actor: user
    )
  end
end
