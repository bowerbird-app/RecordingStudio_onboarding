# frozen_string_literal: true

require "test_helper"

class UsersRegistrationIntegrationIntegrationTest < ActionDispatch::IntegrationTest
  EVENT = RecordingStudioOnboarding::UsersRegistrationIntegration::EVENT
  LEGACY_OTP_EVENT = RecordingStudioOnboarding::UsersRegistrationIntegration::LEGACY_OTP_EVENT

  setup do
    RecordingStudioOnboarding.configure do |config|
      config.provision :new_registration, with: "Dummy::ProvisionRegistration"
    end
  end

  test "password registration event provisions a workspace" do
    user = create_user!("pw")
    assert_provisions_once(user, method: :password)
  end

  test "oauth registration event provisions a workspace" do
    user = create_user!("oauth")
    assert_provisions_once(user, method: :oauth)
  end

  test "otp registration event provisions a workspace" do
    user = create_user!("otp")
    assert_provisions_once(user, method: :otp)
  end

  test "legacy otp event alone does not provision" do
    user = create_user!("legacy-otp")

    assert_no_difference -> { RecordingStudioOnboarding::ProvisioningExecution.count } do
      assert_no_difference -> { Workspace.count } do
        ActiveSupport::Notifications.instrument(
          LEGACY_OTP_EVENT,
          user_id: user.id,
          challenge_id: SecureRandom.uuid
        )
      end
    end
  end

  test "duplicate registration events are idempotent" do
    user = create_user!("idempotent")

    assert_difference -> { RecordingStudioOnboarding::ProvisioningExecution.count }, 1 do
      assert_difference -> { Workspace.count }, 1 do
        emit_registration_completed!(user_id: user.id, method: :password)
        emit_registration_completed!(user_id: user.id, method: :password)
        emit_registration_completed!(user_id: user.id, method: :oauth)
      end
    end

    execution = RecordingStudioOnboarding::ProvisioningExecution.find_by!(
      provisioner: "new_registration",
      actor: user
    )
    assert_equal "completed", execution.status
    assert_equal "new_registration:User:#{user.id}", execution.idempotency_key
  end

  private

  def create_user!(label)
    User.create!(
      email: "#{label}-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
  end

  def emit_registration_completed!(user_id:, method:)
    ActiveSupport::Notifications.instrument(EVENT, user_id: user_id, method: method)
  end

  def assert_provisions_once(user, method:)
    assert_difference -> { RecordingStudioOnboarding::ProvisioningExecution.count }, 1 do
      assert_difference -> { Workspace.count }, 1 do
        emit_registration_completed!(user_id: user.id, method: method)
      end
    end

    execution = RecordingStudioOnboarding::ProvisioningExecution.find_by!(
      provisioner: "new_registration",
      actor: user
    )
    assert_equal "completed", execution.status
  end
end
