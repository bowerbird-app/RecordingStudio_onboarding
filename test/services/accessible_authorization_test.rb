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

  private

  def build_record(type_name, id)
    type = Class.new do
      define_singleton_method(:base_class) { self }
      define_singleton_method(:name) { type_name }
    end
    record = Object.new
    record.define_singleton_method(:id) { id }
    record.define_singleton_method(:class) { type }
    record
  end
end
