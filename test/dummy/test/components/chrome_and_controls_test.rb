# frozen_string_literal: true

require "test_helper"

class ChromeAndControlsTest < ViewComponent::TestCase
  setup do
    @configuration = RecordingStudioOnboarding::Configuration.new
    @configuration.flow :demo do
      step :welcome, component: "X", controls: %i[continue], skippable: false,
           button_positions: { continue: :full }
      step :details, component: "X", controls: %i[continue], skippable: true,
           button_positions: { continue: :right }
      step :done, component: "X", controls: %i[continue], skippable: false,
           button_positions: { continue: :left }
    end
    @definition = @configuration.flow_for(:demo)
  end

  test "chrome hides back on first step and skip when not skippable" do
    run = fake_run(step_key: :welcome)
    render_inline RecordingStudioOnboarding::ChromeComponent.new(run: run, preview: true)

    refute_includes rendered_content, "onboarding-chrome"
  end

  test "chrome shows back and skip on a middle skippable step" do
    run = fake_run(step_key: :details)
    render_inline RecordingStudioOnboarding::ChromeComponent.new(run: run, preview: true)

    html = rendered_content
    assert_includes html, "onboarding-chrome"
    assert_includes html, "&lt; Back"
    assert_includes html, "Skip"
  end

  test "controls render full width continue and never exit" do
    run = fake_run(step_key: :welcome)
    render_inline RecordingStudioOnboarding::ControlsComponent.new(run: run, preview: true)

    html = rendered_content
    assert_includes html, "onboarding-controls"
    assert_includes html, "control-advance"
    assert_includes html, "w-full"
    refute_includes html, "control-exit"
    refute_includes html, "control-back"
    refute_includes html, "control-skip"
  end

  test "progress bar starts colored on step one" do
    run = fake_run(step_key: :welcome)
    render_inline RecordingStudioOnboarding::ProgressComponent.new(run: run)

    html = rendered_content
    assert_includes html, 'data-mode="bar"'
    assert_includes html, 'aria-valuenow="1.0"'
    assert_includes html, 'aria-valuemax="3.0"'
  end

  private

  def fake_run(step_key:)
    Struct.new(
      :flow_key, :current_step_key, :definition, :open?, :step_progresses, :current_step,
      :preview?, keyword_init: true
    ).new(
      flow_key: "demo",
      current_step_key: step_key.to_s,
      definition: @definition,
      open?: true,
      step_progresses: [],
      current_step: @definition.step_for(step_key),
      preview?: true
    )
  end
end
