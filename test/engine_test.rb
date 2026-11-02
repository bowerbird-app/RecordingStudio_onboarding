# frozen_string_literal: true

require "test_helper"
# recording_studio loads ActiveRecord. ActionController is required so the
# descendant-filter tests run in this suite instead of skipping.
require "active_record"
require "action_controller"

class EngineTest < Minitest::Test
  def setup
    @original_configuration = RecordingStudioOnboarding.configuration
    RecordingStudioOnboarding.reset_for_tests!
  end

  def teardown
    RecordingStudioOnboarding.configuration.hooks.clear!
    RecordingStudioOnboarding.reset_for_tests!(configuration: @original_configuration)
  end

  def test_before_and_after_initialize_initializers_run_hooks
    before_called = false
    after_called = false

    RecordingStudioOnboarding.configuration.hooks.before_initialize { |_engine| before_called = true }
    RecordingStudioOnboarding.configuration.hooks.after_initialize { |_engine| after_called = true }

    find_initializer("recording_studio_onboarding.before_initialize").block.call(Object.new)
    find_initializer("recording_studio_onboarding.after_initialize").block.call(Object.new)

    assert before_called
    assert after_called
  end

  def test_load_config_runs_on_configuration_hook
    hook_called = false
    hook_payload = nil
    RecordingStudioOnboarding.configuration.hooks.on_configuration do |cfg|
      hook_called = true
      hook_payload = cfg
    end

    xcfg = Struct.new(:recording_studio_onboarding).new({ unknown: true })
    app_config = Struct.new(:x).new(xcfg)
    app = Struct.new(:config) do
      def config_for(_name)
        { unknown_yaml: true }
      end
    end.new(app_config)

    find_initializer("recording_studio_onboarding.load_config").block.call(app)

    assert hook_called
    assert_equal RecordingStudioOnboarding.configuration, hook_payload
    assert_empty RecordingStudioOnboarding.configuration.provisioners
  end

  def test_load_config_ignores_missing_yaml_and_uses_each_pair_fallback
    pair_config = Class.new do
      def each_pair
        yield(:unknown_key, 15)
      end
    end.new

    xcfg = Struct.new(:recording_studio_onboarding).new(pair_config)
    app_config = Struct.new(:x).new(xcfg)

    app = Struct.new(:config) do
      def config_for(_name)
        raise "Could not load configuration. No such file - config/recording_studio_onboarding.yml"
      end
    end.new(app_config)

    find_initializer("recording_studio_onboarding.load_config").block.call(app)

    refute_respond_to RecordingStudioOnboarding.configuration, :unknown_key
  end

  def test_load_config_raises_each_pair_errors
    bad_pair_config = Class.new do
      def each_pair
        raise "bad pair"
      end
    end.new

    xcfg = Struct.new(:recording_studio_onboarding).new(bad_pair_config)
    app_config = Struct.new(:x).new(xcfg)
    app = Struct.new(:config) do
      def config_for(_name)
        { unknown_yaml: "ok" }
      end
    end.new(app_config)

    error = assert_raises(RuntimeError) do
      find_initializer("recording_studio_onboarding.load_config").block.call(app)
    end
    assert_equal "bad pair", error.message
  end

  def test_load_config_is_noop_without_config_sources
    app = Struct.new(:config).new(Object.new)

    find_initializer("recording_studio_onboarding.load_config").block.call(app)

    assert_empty RecordingStudioOnboarding.configuration.provisioners
  end

  def test_load_config_raises_yaml_enumeration_errors
    yaml = Class.new do
      def each
        raise "bad yaml"
      end
    end.new

    xcfg = Struct.new(:recording_studio_onboarding).new({ unknown: 22 })
    app_config = Struct.new(:x).new(xcfg)
    app = Struct.new(:config) do
      attr_accessor :yaml

      def config_for(_name)
        @yaml
      end
    end.new(app_config)
    app.yaml = yaml

    error = assert_raises(RuntimeError) do
      find_initializer("recording_studio_onboarding.load_config").block.call(app)
    end
    assert_equal "bad yaml", error.message
  end

  def test_load_config_raises_unrelated_config_for_errors
    app_config = Struct.new(:x).new(Object.new)
    app = Struct.new(:config) do
      def config_for(_name)
        raise "database down"
      end
    end.new(app_config)

    error = assert_raises(RuntimeError) do
      find_initializer("recording_studio_onboarding.load_config").block.call(app)
    end
    assert_equal "database down", error.message
  end

  def test_apply_extension_initializers_register_to_prepare_callbacks
    to_prepare_blocks = []
    config_stub = Object.new
    config_stub.define_singleton_method(:to_prepare) do |&block|
      to_prepare_blocks << block
    end

    RecordingStudioOnboarding::Engine.stub(:config, config_stub) do
      find_initializer("recording_studio_onboarding.apply_model_extensions").block.call
      find_initializer("recording_studio_onboarding.apply_controller_extensions").block.call
    end

    assert_equal 2, to_prepare_blocks.size
  end

  def test_model_extension_initializer_skips_abstract_models
    to_prepare_blocks = []
    config_stub = Object.new
    config_stub.define_singleton_method(:to_prepare) do |&block|
      to_prepare_blocks << block
    end

    abstract_model = Class.new do
      def self.abstract_class?
        true
      end
    end
    concrete_model = Class.new do
      def self.abstract_class?
        false
      end
    end
    applied = []

    RecordingStudioOnboarding::Engine.stub(:config, config_stub) do
      find_initializer("recording_studio_onboarding.apply_model_extensions").block.call
    end

    ActiveRecord::Base.stub(:descendants, [abstract_model, concrete_model]) do
      RecordingStudioOnboarding::Engine.stub(:apply_model_extensions, ->(model) { applied << model }) do
        to_prepare_blocks.first.call
      end
    end

    assert_equal [concrete_model], applied
  end

  def test_controller_extension_initializer_applies_all_controllers
    to_prepare_blocks = []
    config_stub = Object.new
    config_stub.define_singleton_method(:to_prepare) do |&block|
      to_prepare_blocks << block
    end

    first_controller = Class.new
    second_controller = Class.new
    applied = []

    RecordingStudioOnboarding::Engine.stub(:config, config_stub) do
      find_initializer("recording_studio_onboarding.apply_controller_extensions").block.call
    end

    ActionController::Base.stub(:descendants, [first_controller, second_controller]) do
      RecordingStudioOnboarding::Engine.stub(:apply_controller_extensions, ->(controller) { applied << controller }) do
        to_prepare_blocks.first.call
      end
    end

    assert_equal [first_controller, second_controller], applied
  end

  def test_apply_model_extensions_adds_registered_methods_once
    model_class = Class.new do
      def self.name
        "ExampleRecord"
      end
    end

    RecordingStudioOnboarding.configuration.hooks.extend_model(:ExampleRecord) do
      def template_extension_method
        :applied
      end
    end

    RecordingStudioOnboarding::Engine.apply_model_extensions(model_class)
    RecordingStudioOnboarding::Engine.apply_model_extensions(model_class)

    instance = model_class.new
    assert_equal :applied, instance.template_extension_method
  end

  def test_apply_controller_extensions_matches_demodulized_name
    controller_class = Class.new do
      def self.name
        "Admin::DashboardController"
      end
    end

    RecordingStudioOnboarding.configuration.hooks.extend_controller(:DashboardController) do
      def template_controller_extension
        :applied
      end
    end

    RecordingStudioOnboarding::Engine.apply_controller_extensions(controller_class)

    instance = controller_class.new
    assert_equal :applied, instance.template_controller_extension
  end

  def test_register_admin_loads_admin_rb_on_prepare
    source = File.read(File.expand_path("../lib/recording_studio_onboarding/engine.rb", __dir__))

    assert_includes source, "load File.expand_path(\"admin.rb\""
  end

  def test_apply_model_returns_without_target
    assert_nil RecordingStudioOnboarding::ExtensionApplier.apply_model(nil)
  end

  def test_apply_model_flattens_compacts_and_dedupes_by_identity
    target = Class.new do
      def self.name
        "ExampleRecord"
      end
    end
    applied = []
    extension = proc { applied << :once }

    RecordingStudioOnboarding.configuration.hooks.stub(
      :model_extensions_for,
      ->(_name) { [nil, [extension, extension]] }
    ) do
      RecordingStudioOnboarding::ExtensionApplier.apply_model(target)
    end

    assert_equal [:once], applied
  end

  def test_apply_controller_matches_demodulized_name
    controller_class = Class.new do
      def self.name
        "Admin::ReportsController"
      end
    end
    RecordingStudioOnboarding.configuration.hooks.extend_controller(:ReportsController) do
      def demodulized_extension
        :applied
      end
    end

    RecordingStudioOnboarding::ExtensionApplier.apply_controller(controller_class)

    assert_equal :applied, controller_class.new.demodulized_extension
  end

  def test_apply_controller_drops_duplicate_extension_keys
    controller_class = Class.new do
      def self.name
        "ReportsController"
      end
    end
    names = []
    RecordingStudioOnboarding.configuration.hooks.stub(
      :controller_extensions_for,
      lambda { |name|
        names << name
        []
      }
    ) do
      RecordingStudioOnboarding::ExtensionApplier.apply_controller(controller_class)
    end

    assert_equal [:ReportsController], names
  end

  private

  def find_initializer(name)
    RecordingStudioOnboarding::Engine.initializers.find { |initializer| initializer.name == name }
  end
end
