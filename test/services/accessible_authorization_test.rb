# frozen_string_literal: true

require "test_helper"
require "recording_studio_onboarding/services/accessible_authorization"

class AccessibleAuthorizationTest < Minitest::Test
  FakeDefinition = Struct.new(:scope)

  def test_user_scope_matches_actor_identity
    actor = build_record("User", 1)
    other = build_record("User", 2)

    assert RecordingStudioOnboarding::Services::AccessibleAuthorization.allowed_for_scope?(
      definition: FakeDefinition.new(:user),
      scope: actor,
      actor: actor
    )
    refute RecordingStudioOnboarding::Services::AccessibleAuthorization.allowed_for_scope?(
      definition: FakeDefinition.new(:user),
      scope: actor,
      actor: other
    )
  end

  def test_workspace_scope_denies_when_accessible_is_missing
    actor = build_record("User", 1)
    workspace = build_record("Workspace", 9)

    refute RecordingStudioOnboarding::Services::AccessibleAuthorization.allowed_for_scope?(
      definition: FakeDefinition.new(:workspace),
      scope: workspace,
      actor: actor
    )
  end

  def test_nil_actor_is_denied
    refute RecordingStudioOnboarding::Services::AccessibleAuthorization.allowed?(
      actor: nil,
      record: build_record("Workspace", 1)
    )
  end

  def test_matching_actor_and_record_still_require_accessible
    actor = build_record("User", 1)

    refute RecordingStudioOnboarding::Services::AccessibleAuthorization.allowed?(
      actor: actor,
      record: actor
    )
  end

  def test_allowed_does_not_call_root_recording_for
    skip "Accessible recording lookup is required" unless defined?(RecordingStudioAccessible)

    actor = build_record("User", 1)
    workspace = build_record("Workspace", 9)
    called = false

    RecordingStudio.stub(:root_allowed?, true) do
      RecordingStudio.stub(:root_recording_for, lambda { |*|
        called = true
        raise "authorization must not create roots"
      }) do
        refute RecordingStudioOnboarding::Services::AccessibleAuthorization.allowed?(
          actor: actor,
          record: workspace
        )
      end
    end

    refute called, "authorization looked up by creating a root recording"
  end
end
