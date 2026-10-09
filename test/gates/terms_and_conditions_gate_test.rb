# frozen_string_literal: true

require "test_helper"

class TermsAndConditionsGateTest < Minitest::Test
  class FakeController
    attr_reader :stored

    def initialize
      @stored = nil
    end

    def store_location_for(scope, path)
      @stored = [scope, path]
    end

    def recording_studio_terms_and_conditions
      self
    end

    def acceptance_path
      "/recording_studio_terms_and_conditions/acceptance"
    end
  end

  def setup
    @configuration = RecordingStudioOnboarding::Configuration.new
    @previous = RecordingStudioOnboarding.instance_variable_get(:@configuration)
    RecordingStudioOnboarding.instance_variable_set(:@configuration, @configuration)
    @controller = FakeController.new
    @actor = Object.new
    @root = Object.new
  end

  def teardown
    RecordingStudioOnboarding.instance_variable_set(:@configuration, @previous)
  end

  def test_not_installed_style_gate_leaves_onboarding_unchanged
    # Hosts without RS Terms register nothing; empty gates mean no deferral.
    assert_empty @configuration.before_onboarding_gates
    path = RecordingStudioOnboarding.before_onboarding_redirect_to(
      @controller,
      actor: @actor,
      return_path: "/onboarding/runs/1"
    )
    assert_nil path
  end

  def test_gate_returns_nil_without_actor
    gate = RecordingStudioOnboarding::Gates::TermsAndConditions.new
    assert_nil gate.call(controller: @controller, actor: nil, return_path: "/onboarding/runs/1")
  end

  def test_gate_source_uses_defined_and_public_terms_api
    source = File.read(
      File.expand_path("../../lib/recording_studio_onboarding/gates/terms_and_conditions.rb", __dir__)
    )

    assert_includes source, "defined?(::RecordingStudioTermsAndConditions)"
    assert_includes source, "requires_acceptance?"
    assert_includes source, "Gate.root_for_acceptance"
    assert_includes source, "Gate.acceptance_path"
    assert_includes source, "store_location_for"
    refute_includes source, "return_to"
  end

  def test_gemspec_has_no_terms_dependency
    gemspec = File.read(File.expand_path("../../recording_studio_onboarding.gemspec", __dir__))
    refute_includes gemspec, "recording_studio_terms_and_conditions"
    refute_includes gemspec, "recording_studio_publishable"
  end

  def test_gate_returns_nil_when_nothing_due
    skip "RS Terms not loaded in gem suite" unless defined?(::RecordingStudioTermsAndConditions)

    gate = RecordingStudioOnboarding::Gates::TermsAndConditions.new
    ::RecordingStudioTermsAndConditions::Gate.stub(:root_for_acceptance, ->(*) { @root }) do
      ::RecordingStudioTermsAndConditions.stub(:requires_acceptance?, ->(*) { false }) do
        assert_nil gate.call(controller: @controller, actor: @actor, return_path: "/onboarding/runs/1")
      end
    end
    assert_nil @controller.stored
  end

  def test_gate_redirects_to_agree_and_stores_return_path_when_due
    skip "RS Terms not loaded in gem suite" unless defined?(::RecordingStudioTermsAndConditions)

    gate = RecordingStudioOnboarding::Gates::TermsAndConditions.new
    ::RecordingStudioTermsAndConditions::Gate.stub(:root_for_acceptance, ->(*) { @root }) do
      ::RecordingStudioTermsAndConditions.stub(:requires_acceptance?, ->(*) { true }) do
        ::RecordingStudioTermsAndConditions::Gate.stub(
          :acceptance_path,
          ->(*) { "/recording_studio_terms_and_conditions/acceptance" }
        ) do
          path = gate.call(controller: @controller, actor: @actor, return_path: "/onboarding/runs/abc")
          assert_equal "/recording_studio_terms_and_conditions/acceptance", path
        end
      end
    end
    assert_equal [:user, "/onboarding/runs/abc"], @controller.stored
  end

  def test_before_onboarding_first_non_nil_wins
    @configuration.before_onboarding { |_args| nil }
    @configuration.before_onboarding { |_args| "/first" }
    @configuration.before_onboarding { |_args| "/second" }

    path = RecordingStudioOnboarding.before_onboarding_redirect_to(
      @controller,
      actor: @actor,
      return_path: "/x"
    )
    assert_equal "/first", path
  end

  def test_register_if_present_adds_gate_once_when_terms_defined
    skip "RS Terms not loaded in gem suite" unless defined?(::RecordingStudioTermsAndConditions)

    assert_equal 0, @configuration.before_onboarding_gates.size
    RecordingStudioOnboarding::Gates::TermsAndConditions.register_if_present!
    RecordingStudioOnboarding::Gates::TermsAndConditions.register_if_present!
    assert_equal 1, @configuration.before_onboarding_gates.size
    assert_kind_of RecordingStudioOnboarding::Gates::TermsAndConditions,
                   @configuration.before_onboarding_gates.first
  end
end
