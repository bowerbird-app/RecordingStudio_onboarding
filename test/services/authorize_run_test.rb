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
    @original = RecordingStudioOnboarding.instance_variable_get(:@configuration)
    RecordingStudioOnboarding.instance_variable_set(:@configuration, RecordingStudioOnboarding::Configuration.new)
  end

  def teardown
    RecordingStudioOnboarding.instance_variable_set(:@configuration, @original)
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
