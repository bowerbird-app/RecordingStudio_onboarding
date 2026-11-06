# frozen_string_literal: true

require "test_helper"

class AuthorizeWriteTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "write-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @workspace = Workspace.create!(name: "Write Workspace")
    with_actor(@user) do
      @root = RecordingStudio.root_recording_for(@workspace)
      result = RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @user)
      raise result.error if result.failure?
    end
  end

  test "page writes require Accessible edit" do
    page = Page.create!(title: "Denied page")
    stranger = User.create!(
      email: "write-stranger-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )

    assert_raises(RecordingStudio::AuthorizationError) do
      with_actor(stranger) do
        RecordingStudio.record!(
          action: "created",
          recordable: page,
          root_recording: @root,
          parent_recording: @root,
          actor: stranger
        )
      end
    end

    with_actor(@user) do
      event = RecordingStudio.record!(
        action: "created",
        recordable: page,
        root_recording: @root,
        parent_recording: @root,
        actor: @user
      )
      assert event.recording.present?
    end
  end

  test "grant_access writes Access rows through AccessCreationContext" do
    viewer = User.create!(
      email: "write-viewer-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )

    with_actor(@user) do
      result = RecordingStudioAccessible.grant_access(
        recording: @root,
        actor: viewer,
        role: :view,
        manager_actor: @user
      )
      assert result.success?, result.error&.message
    end
  end
end
