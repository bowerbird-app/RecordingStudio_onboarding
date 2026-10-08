# frozen_string_literal: true

require "test_helper"

class FlowRegistryTest < Minitest::Test
  def setup
    @configuration = RecordingStudioOnboarding::Configuration.new
  end

  def test_flow_registers_named_definition
    @configuration.flow :account_setup do
      scope :user
      progress :segments
      dismissible true
      version 2
      step :welcome, component: "Dummy::Welcome"
      step :done, component: "Dummy::Done", show_progress: false
    end

    definition = @configuration.flow_for(:account_setup)
    assert @configuration.flow_registered?(:account_setup)
    assert_equal :user, definition.scope
    assert_equal :segments, definition.progress
    assert_equal true, definition.dismissible
    assert_equal 2, definition.version
    assert_equal %i[welcome done], definition.step_keys
    assert_equal :welcome, definition.first_step_key
    assert_equal 1, definition.visible_steps.size
  end

  def test_flow_requires_name_block_and_steps
    assert_raises(ArgumentError) { @configuration.flow(nil) { step :a, component: "X" } }
    assert_raises(ArgumentError) { @configuration.flow(:x) }
    assert_raises(ArgumentError) do
      @configuration.flow(:empty) do
        scope :user
      end
    end
  end

  def test_flow_rejects_unsupported_scope_and_progress
    assert_raises(ArgumentError) do
      @configuration.flow :bad_scope do
        scope :team
        step :a, component: "X"
      end
    end

    assert_raises(ArgumentError) do
      @configuration.flow :bad_progress do
        progress :pie
        step :a, component: "X"
      end
    end
  end

  def test_to_h_includes_flow_keys
    @configuration.flow :account_setup do
      step :welcome, component: "X"
    end

    assert_equal [:account_setup], @configuration.to_h.fetch(:flows)
  end

  def test_public_api_methods_exist
    %i[start active_run advance back skip dismiss reset mark_viewed].each do |method_name|
      assert_respond_to RecordingStudioOnboarding, method_name
    end
  end
end
