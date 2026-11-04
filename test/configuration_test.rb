# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < Minitest::Test
  def setup
    @configuration = RecordingStudioOnboarding::Configuration.new
  end

  def test_provision_registers_named_handler
    @configuration.provision :new_registration, with: "Dummy::ProvisionRegistration"

    assert @configuration.provisioner_registered?(:new_registration)
    assert_equal "Dummy::ProvisionRegistration", @configuration.provisioner_for(:new_registration)
  end

  def test_provision_requires_name_and_handler
    assert_raises(ArgumentError) { @configuration.provision nil, with: "X" }
    assert_raises(ArgumentError) { @configuration.provision :x, with: nil }
  end

  def test_merge_with_non_enumerable_is_noop
    original = @configuration.to_h
    @configuration.merge!(nil)
    assert_equal original[:provisioners], @configuration.to_h[:provisioners]
  end

  def test_merge_ignores_unknown_keys
    @configuration.merge!(unknown_key: "ignored", timeout: 7)
    refute_respond_to @configuration, :unknown_key
    refute_respond_to @configuration, :timeout
  end

  def test_to_h_reports_provisioners_flows_and_hook_counts
    @configuration.provision :new_registration, with: "X"
    @configuration.flow :account_setup do
      step :welcome, component: "X"
    end
    @configuration.before_onboarding { nil }
    @configuration.hooks.before_initialize { nil }
    @configuration.hooks.before_initialize { nil }

    result = @configuration.to_h

    assert_equal [:new_registration], result.fetch(:provisioners)
    assert_equal [:account_setup], result.fetch(:flows)
    assert_equal 1, result.fetch(:before_onboarding_gates)
    assert_equal 2, result.fetch(:hooks_registered).fetch(:before_initialize)
  end

  def test_before_onboarding_requires_callable
    assert_raises(ArgumentError) { @configuration.before_onboarding(nil) }
    assert_raises(ArgumentError) { @configuration.before_onboarding(Object.new) }
  end

  def test_configure_without_block_is_safe
    RecordingStudioOnboarding.configure
    assert_kind_of RecordingStudioOnboarding::Configuration, RecordingStudioOnboarding.configuration
  end

  def test_initialize_exposes_hooks
    assert_instance_of RecordingStudio::Hooks, @configuration.hooks
    assert_empty @configuration.provisioners
    assert_empty @configuration.flows
    assert_nil @configuration.layout
  end

  def test_layout_accepts_nil_false_and_name
    @configuration.layout = nil
    assert_nil @configuration.layout

    @configuration.layout = false
    assert_equal false, @configuration.layout

    @configuration.layout = "recording_studio/default_layout"
    assert_equal "recording_studio/default_layout", @configuration.layout
  end

  def test_reset_for_tests_replaces_configuration
    original = RecordingStudioOnboarding.configuration
    replacement = RecordingStudioOnboarding::Configuration.new
    returned = RecordingStudioOnboarding.reset_for_tests!(configuration: replacement)

    assert_same replacement, returned
    assert_same replacement, RecordingStudioOnboarding.configuration
  ensure
    RecordingStudioOnboarding.reset_for_tests!(configuration: original)
  end

  def test_delete_and_clear_flows
    @configuration.flow :account_setup do
      step :welcome, component: "X"
    end
    @configuration.flow :workspace_setup do
      step :name, component: "X"
    end

    @configuration.delete_flow(:account_setup)
    refute @configuration.flow_registered?(:account_setup)
    assert @configuration.flow_registered?(:workspace_setup)

    @configuration.clear_flows
    assert_empty @configuration.flows
  end
end
