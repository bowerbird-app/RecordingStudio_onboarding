# frozen_string_literal: true

require "test_helper"
require "recording_studio_onboarding/services/authorize_run"

class AuthorizeRunTest < Minitest::Test
  class FakeRun
    attr_reader :definition, :scope

    def initialize(definition:, scope:)
      @definition = definition
      @scope = scope
    end
  end

  class FakeDefinition
    attr_reader :scope

    def initialize(scope)
      @scope = scope
    end
  end

  def setup
    @original = RecordingStudioOnboarding.configuration
    RecordingStudioOnboarding.reset_for_tests!
  end

  def teardown
    RecordingStudioOnboarding.reset_for_tests!(configuration: @original)
  end

  def test_nil_actor_is_denied
    run = FakeRun.new(definition: FakeDefinition.new(:user), scope: build_record("User", 1))
    refute RecordingStudioOnboarding::Services::AuthorizeRun.call(run, actor: nil)
  end

  def test_custom_policy_can_only_further_deny
    actor = build_record("User", 1)
    run = FakeRun.new(definition: FakeDefinition.new(:user), scope: actor)
    RecordingStudioOnboarding.configuration.authorize_run = ->(_run, _actor) { false }

    refute RecordingStudioOnboarding::Services::AuthorizeRun.call(run, actor: actor)
  end

  def test_custom_policy_true_keeps_matching_user_scope
    actor = build_record("User", 1)
    run = FakeRun.new(definition: FakeDefinition.new(:user), scope: actor)
    RecordingStudioOnboarding.configuration.authorize_run = ->(_run, _actor) { true }

    assert RecordingStudioOnboarding::Services::AuthorizeRun.call(run, actor: actor)
  end

  def test_custom_policy_cannot_widen_past_accessible
    actor = build_record("User", 1)
    workspace = build_record("Workspace", 9)
    run = FakeRun.new(definition: FakeDefinition.new(:workspace), scope: workspace)
    RecordingStudioOnboarding.configuration.authorize_run = ->(_run, _actor) { true }

    refute RecordingStudioOnboarding::Services::AuthorizeRun.call(run, actor: actor)
  end

  def test_user_scope_requires_same_actor
    user_a = build_record("User", 1)
    user_b = build_record("User", 2)
    run_a = FakeRun.new(definition: FakeDefinition.new(:user), scope: user_a)

    assert RecordingStudioOnboarding::Services::AuthorizeRun.call(run_a, actor: user_a)
    refute RecordingStudioOnboarding::Services::AuthorizeRun.call(run_a, actor: user_b)
  end

  def test_missing_recording_is_denied
    skip "Accessible recording lookup is required" unless defined?(RecordingStudioAccessible)

    actor = build_record("User", 1)
    workspace = Object.new
    run = FakeRun.new(definition: FakeDefinition.new(:workspace), scope: workspace)
    authorizer = RecordingStudioOnboarding::Services::AuthorizeRun.new(run, actor: actor)

    RecordingStudio.stub(:root_allowed?, true) do
      RecordingStudio::Recording.stub(:find_by, ->(*) { raise ActiveRecord::RecordNotFound, "missing" }) do
        refute authorizer.call
      end
    end
  end

  def test_unexpected_lookup_error_is_denied
    skip "Accessible recording lookup is required" unless defined?(RecordingStudioAccessible)

    actor = build_record("User", 1)
    workspace = Object.new
    run = FakeRun.new(definition: FakeDefinition.new(:workspace), scope: workspace)
    authorizer = RecordingStudioOnboarding::Services::AuthorizeRun.new(run, actor: actor)

    RecordingStudio.stub(:root_allowed?, true) do
      RecordingStudio::Recording.stub(:find_by, ->(*) { raise ArgumentError, "blown call" }) do
        refute authorizer.call
      end
    end
  end
end
