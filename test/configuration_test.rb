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

  def test_to_h_reports_provisioners_and_hook_counts
    @configuration.provision :new_registration, with: "X"
    @configuration.hooks.before_initialize { nil }
    @configuration.hooks.before_initialize { nil }

    result = @configuration.to_h

    assert_equal [:new_registration], result.fetch(:provisioners)
    assert_equal 2, result.fetch(:hooks_registered).fetch(:before_initialize)
  end

  def test_configure_without_block_is_safe
    RecordingStudioOnboarding.configure
    assert_kind_of RecordingStudioOnboarding::Configuration, RecordingStudioOnboarding.configuration
  end

  def test_initialize_exposes_hooks
    assert_instance_of RecordingStudio::Hooks, @configuration.hooks
    assert_empty @configuration.provisioners
  end
end
