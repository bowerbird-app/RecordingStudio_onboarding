# frozen_string_literal: true

require "test_helper"

class RsUsersPasswordRegistrationTest < ActionDispatch::IntegrationTest
  setup do
    RecordingStudioOnboarding.configure do |config|
      config.provision :new_registration, with: "Dummy::ProvisionRegistration"
    end
  end

  test "RS Users password sign-up provisions a workspace" do
    email = "rs-user-#{SecureRandom.hex(4)}@example.com"

    post new_user_registration_path, params: { user: { email: email } }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_difference -> { RecordingStudioOnboarding::ProvisioningExecution.count }, 1 do
      assert_difference -> { Workspace.count }, 1 do
        assert_difference -> { User.count }, 1 do
          post user_registration_path, params: {
            user: { email: email, password: "Password123!" }
          }
        end
      end
    end

    user = User.find_by!(email: email)
    assert_equal "password", user.registered_with
    execution = RecordingStudioOnboarding::ProvisioningExecution.find_by!(
      provisioner: "new_registration",
      actor: user
    )
    assert_equal "completed", execution.status
    assert_equal "new_registration:User:#{user.id}", execution.idempotency_key
  end

  test "RS Users sign-up page is the auth engine form" do
    get new_user_registration_path

    assert_response :success
    assert_select "html[data-theme='rounded']"
    assert_select "input#user_email[type='email']"
    assert_select "button[type='submit']", text: /Continue with email/i
    assert_select "input#user_password", count: 0
  end
end
