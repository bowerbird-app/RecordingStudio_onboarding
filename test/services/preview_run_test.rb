# frozen_string_literal: true

require "test_helper"
require "recording_studio_onboarding/services/preview_run"

class PreviewRunTest < Minitest::Test
  def setup
    RecordingStudioOnboarding.configure do |config|
      config.instance_variable_set(:@flows, {})
      config.preview_context = ->(**) { { actor: :preview_actor, subject: nil } }
      config.flow :preview_demo do
        scope :user
        version 1
        step :welcome, component: "Object", controls: %i[continue exit]
        step :done, component: "Object", controls: %i[continue]
      end
    end
  end

  def test_builds_in_memory_preview_run
    preview = RecordingStudioOnboarding::Services::PreviewRun.call(
      flow_key: :preview_demo,
      step_key: :welcome
    )

    assert preview.preview?
    assert_equal "preview_demo", preview.flow_key
    assert_equal "welcome", preview.current_step_key
    assert_equal :preview_actor, preview.initiating_actor
    assert_equal "Symbol", preview.initiating_actor_type
    assert_nil preview.initiating_actor_id
    assert_equal :preview_actor, preview.scope
    assert_equal "Symbol", preview.scope_type
    assert_nil preview.scope_id
    assert_equal 2, preview.step_progresses.size
    assert_equal "pending", preview.step_progresses.first.status
  end

  def test_scope_type_matches_flow_run_polymorphic_columns
    workspace_class = Class.new do
      def self.base_class = self
      def self.name = "Workspace"
      def id = 7
    end
    workspace = workspace_class.new

    RecordingStudioOnboarding.configuration.preview_context = lambda do |**|
      { actor: :preview_actor, subject: workspace }
    end

    preview = RecordingStudioOnboarding::Services::PreviewRun.call(
      flow_key: :preview_demo,
      step_key: :welcome
    )

    assert_equal workspace, preview.scope
    assert_equal "Workspace", preview.scope_type
    assert_equal 7, preview.scope_id
  end

  def test_public_preview_api
    preview = RecordingStudioOnboarding.preview(:preview_demo, :done)
    assert_equal "done", preview.current_step_key
    assert preview.preview?
  end
end
