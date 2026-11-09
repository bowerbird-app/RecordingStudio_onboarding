# frozen_string_literal: true

require "test_helper"
require "recording_studio_onboarding/services/accessible_authorization"

class AuthorizationLookupTest < ActionDispatch::IntegrationTest
  test "denied allowed? and start insert neither recordings nor flow runs" do
    workspace = Workspace.create!(name: "Lookup Workspace #{SecureRandom.hex(4)}")
    stranger = User.create!(
      email: "lookup-stranger-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )

    recordings_before = RecordingStudio::Recording.count
    runs_before = RecordingStudioOnboarding::FlowRun.count

    refute RecordingStudioOnboarding::Services::AccessibleAuthorization.allowed?(
      actor: stranger,
      record: workspace
    )
    assert_equal recordings_before, RecordingStudio::Recording.count
    assert_equal runs_before, RecordingStudioOnboarding::FlowRun.count

    assert_raises(RecordingStudioOnboarding::Unauthorized) do
      RecordingStudioOnboarding.start(:workspace_setup, actor: stranger, subject: workspace)
    end
    assert_equal recordings_before, RecordingStudio::Recording.count
    assert_equal runs_before, RecordingStudioOnboarding::FlowRun.count
    refute RecordingStudio::Recording.exists?(recordable: workspace)
  end
end
