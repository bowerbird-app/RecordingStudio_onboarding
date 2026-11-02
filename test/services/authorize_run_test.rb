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
    run = FakeRun.new(definition: FakeDefinition.new(:user), scope: Object.new)
    refute RecordingStudioOnboarding::Services::AuthorizeRun.call(run, actor: nil)
  end

  def test_custom_policy_is_used
    actor = Object.new
    run = FakeRun.new(definition: FakeDefinition.new(:user), scope: actor)
    RecordingStudioOnboarding.configuration.authorize_run = ->(_run, _actor) { false }

    refute RecordingStudioOnboarding::Services::AuthorizeRun.call(run, actor: actor)
  end

  def test_user_scope_requires_same_actor
    user_a = build_record("User", 1)
    user_b = build_record("User", 2)
    run_a = FakeRun.new(definition: FakeDefinition.new(:user), scope: user_a)

    assert RecordingStudioOnboarding::Services::AuthorizeRun.call(run_a, actor: user_a)
    refute RecordingStudioOnboarding::Services::AuthorizeRun.call(run_a, actor: user_b)
  end

  def test_missing_recording_is_denied_without_swallowing_other_errors
    skip "Accessible recording lookup is required" unless defined?(RecordingStudioAccessible)
    skip "ActiveRecord is required for recording lookup" unless defined?(ActiveRecord::RecordNotFound)

    actor = build_record("User", 1)
    workspace = Object.new
    run = FakeRun.new(definition: FakeDefinition.new(:workspace), scope: workspace)
    authorizer = RecordingStudioOnboarding::Services::AuthorizeRun.new(run, actor: actor)

    RecordingStudio.stub(:root_allowed?, true) do
      RecordingStudio.stub(:root_recording_for, ->(*) { raise ActiveRecord::RecordNotFound, "missing" }) do
        refute authorizer.call
      end
    end

    RecordingStudio.stub(:root_allowed?, true) do
      RecordingStudio.stub(:root_recording_for, ->(*) { raise ArgumentError, "blown call" }) do
        error = assert_raises(ArgumentError) { authorizer.call }
        assert_equal "blown call", error.message
      end
    end
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
