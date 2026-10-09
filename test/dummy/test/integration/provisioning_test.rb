# frozen_string_literal: true

require "test_helper"

class ProvisioningTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    RecordingStudioOnboarding.configure do |config|
      config.provision :new_registration, with: "Dummy::ProvisionRegistration"
    end
    OmniAuth.config.test_mode = true
    clear_omniauth_mocks!
  end

  teardown do
    clear_omniauth_mocks!
  end

  test "RS Users password registration provisions a workspace exactly once" do
    email = "new-user-#{SecureRandom.hex(4)}@example.com"

    post new_user_registration_path, params: { user: { email: email } }
    assert_response :redirect
    follow_redirect!

    assert_difference -> { RecordingStudioOnboarding::ProvisioningExecution.count }, 1 do
      assert_difference -> { Workspace.count }, 1 do
        post user_registration_path, params: {
          user: { email: email, password: "Password123!" }
        }
      end
    end

    user = User.find_by!(email: email)
    execution = RecordingStudioOnboarding::ProvisioningExecution.find_by!(
      provisioner: "new_registration",
      actor: user
    )
    assert_equal "completed", execution.status
    assert_equal "new_registration:User:#{user.id}", execution.idempotency_key

    workspaces = owned_workspaces_for(user)
    assert_equal 1, workspaces.size
    assert_match(/Workspace\z/, workspaces.first.name)

    assert_no_difference -> { Workspace.count } do
      assert_no_difference -> { RecordingStudioOnboarding::ProvisioningExecution.count } do
        ActiveSupport::Notifications.instrument(
          "registration.completed.recording_studio_user",
          user_id: user.id,
          method: :password
        )
        RecordingStudioOnboarding.provision(:new_registration, actor: user, subject: user)
      end
    end

    assert_equal "completed", execution.reload.status
  end

  test "RS Users oauth new-user registration provisions a workspace" do
    email = "oauth-user-#{SecureRandom.hex(4)}@example.com"
    mock_provider_auth!(
      :google_oauth2,
      uid: "oauth-#{SecureRandom.hex(4)}",
      email: email
    )

    assert_difference -> { RecordingStudioOnboarding::ProvisioningExecution.count }, 1 do
      assert_difference -> { Workspace.count }, 1 do
        assert_difference -> { User.count }, 1 do
          get user_google_oauth2_omniauth_callback_path
        end
      end
    end

    user = User.find_by!(email: email)
    execution = RecordingStudioOnboarding::ProvisioningExecution.find_by!(
      provisioner: "new_registration",
      actor: user
    )
    assert_equal "completed", execution.status
  end

  test "registration completed event provisions a workspace exactly once" do
    user = User.create!(
      email: "event-user-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )

    assert_difference -> { RecordingStudioOnboarding::ProvisioningExecution.count }, 1 do
      assert_difference -> { Workspace.count }, 1 do
        ActiveSupport::Notifications.instrument(
          "registration.completed.recording_studio_user",
          user_id: user.id,
          method: :password
        )
      end
    end

    execution = RecordingStudioOnboarding::ProvisioningExecution.find_by!(
      provisioner: "new_registration",
      actor: user
    )
    assert_equal "completed", execution.status
    assert_equal "new_registration:User:#{user.id}", execution.idempotency_key

    workspaces = owned_workspaces_for(user)
    assert_equal 1, workspaces.size
    assert_match(/Workspace\z/, workspaces.first.name)

    assert_no_difference -> { Workspace.count } do
      assert_no_difference -> { RecordingStudioOnboarding::ProvisioningExecution.count } do
        ActiveSupport::Notifications.instrument(
          "registration.completed.recording_studio_user",
          user_id: user.id,
          method: :password
        )
        RecordingStudioOnboarding.provision(:new_registration, actor: user, subject: user)
      end
    end

    assert_equal "completed", execution.reload.status
  end

  test "existing user login does not provision" do
    user = User.create!(
      email: "existing-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )

    assert_no_difference -> { RecordingStudioOnboarding::ProvisioningExecution.count } do
      assert_no_difference -> { Workspace.count } do
        post new_user_session_path, params: { user: { email: user.email } }
        assert_response :redirect
        follow_redirect!
        post user_session_path, params: {
          user: { email: user.email, password: "Password123!" }
        }
      end
    end

    assert_response :redirect
  end

  test "failed provisioning can be retried with the same idempotency key" do
    user = User.create!(
      email: "retry-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )

    exploding = Class.new do
      def self.call(**)
        raise StandardError, "boom password=secret-value"
      end
    end
    RecordingStudioOnboarding.configuration.provision :flaky, with: exploding

    assert_raises(StandardError) do
      RecordingStudioOnboarding.provision(:flaky, actor: user, subject: user)
    end

    execution = RecordingStudioOnboarding::ProvisioningExecution.find_by!(provisioner: "flaky", actor: user)
    assert_equal "failed", execution.status
    assert_includes execution.failure_details, "password=[FILTERED]"
    refute_includes execution.failure_details, "secret-value"

    RecordingStudioOnboarding.configuration.provision :flaky, with: ->(**) { :ok }

    result = RecordingStudioOnboarding.provision(:flaky, actor: user, subject: user)
    assert_equal execution.id, result.id
    assert_equal "completed", result.status
    assert_nil result.failure_details
  end

  test "concurrent duplicate calls share one completed execution" do
    user = User.create!(
      email: "race-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )

    call_count = 0
    mutex = Mutex.new

    handler = lambda do |**|
      mutex.synchronize { call_count += 1 }
      sleep 0.05
      :ok
    end
    RecordingStudioOnboarding.configuration.provision :race, with: handler

    threads = 2.times.map do
      Thread.new do
        RecordingStudioOnboarding.provision(:race, actor: user, subject: user)
      end
    end
    threads.each(&:join)

    executions = RecordingStudioOnboarding::ProvisioningExecution.where(provisioner: "race", actor: user)
    assert_equal 1, executions.count
    assert_equal "completed", executions.first.reload.status
    assert_equal 1, call_count
  end

  test "provisioning status page shows executions and workspaces" do
    email = "status-#{SecureRandom.hex(4)}@example.com"
    post new_user_registration_path, params: { user: { email: email } }
    follow_redirect!
    post user_registration_path, params: {
      user: { email: email, password: "Password123!" }
    }

    user = User.find_by!(email: email)
    sign_in user
    get provisioning_path

    assert_response :success
    assert_match(/Provisioning status/, response.body)
    assert_match(/new_registration/, response.body)
    assert_match(/completed/, response.body)
    assert_select "[data-testid='provisioned-workspace']"
  end

  test "home page describes onboarding provisioning" do
    user = User.create!(
      email: "home-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    sign_in user
    get root_path

    assert_response :success
    assert_match(/Recording Studio Onboarding/, response.body)
    assert_match(/registration\.completed\.recording_studio_user/, response.body)
  end

  private

  def owned_workspaces_for(user)
    root_ids = RecordingStudioAccessible.root_recording_ids_for(actor: user, minimum_role: :admin)
    RecordingStudio::Recording.where(id: root_ids, recordable_type: "Workspace").filter_map(&:recordable)
  end

  def clear_omniauth_mocks!
    %i[google_oauth2 microsoft_graph apple linkedin instagram].each do |provider|
      OmniAuth.config.mock_auth[provider] = nil
    end
  end

  def mock_provider_auth!(provider, uid:, email:, first_name: "OAuth", last_name: "User")
    OmniAuth.config.mock_auth[provider] = OmniAuth::AuthHash.new(
      provider: provider.to_s,
      uid: uid,
      info: {
        email: email,
        name: "#{first_name} #{last_name}",
        first_name: first_name,
        last_name: last_name
      }
    )
  end
end
