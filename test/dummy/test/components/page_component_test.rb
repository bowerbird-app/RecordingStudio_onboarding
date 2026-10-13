# frozen_string_literal: true

require "test_helper"

class PageComponentTest < ViewComponent::TestCase
  setup do
    @configuration = RecordingStudioOnboarding::Configuration.new
    @configuration.flow :demo do
      step :one, component: "RecordingStudioOnboarding::PageComponent"
    end
    @run = Struct.new(:flow_key, :current_step_key, :definition, :open?, :step_progresses, keyword_init: true).new(
      flow_key: "demo",
      current_step_key: "one",
      definition: @configuration.flow_for(:demo),
      open?: true,
      step_progresses: []
    )
    @step = @run.definition.step_for(:one)
  end

  test "splash wins over image_url and tints the overlay" do
    render_inline RecordingStudioOnboarding::PageComponent.new(
      run: @run,
      step: @step,
      title: "Splash title",
      content: "<p>Hello <strong>there</strong></p>",
      splash_image_url: Dummy::Onboarding::DemoImage::URL,
      image_url: "https://example.com/should-not-appear.jpg"
    )

    html = rendered_content
    assert_includes html, 'data-layout="splash"'
    assert_includes html, "Splash title"
    assert_includes html, "<strong>there</strong>"
    assert_includes html, Dummy::Onboarding::DemoImage::URL
    refute_includes html, "should-not-appear.jpg"
  end

  test "image_url renders top-card layout" do
    render_inline RecordingStudioOnboarding::PageComponent.new(
      run: @run,
      step: @step,
      title: "Card title",
      content: "<p>Body copy</p>",
      image_url: Dummy::Onboarding::DemoImage::URL
    )

    html = rendered_content
    assert_includes html, 'data-layout="top-card"'
    assert_includes html, Dummy::Onboarding::DemoImage::URL
    assert_includes html, "Card title"
    assert_includes html, "Body copy"
  end

  test "plain layout when no images are set" do
    render_inline RecordingStudioOnboarding::PageComponent.new(
      run: @run,
      step: @step,
      title: "Words only",
      content: "<p>No picture</p>"
    )

    html = rendered_content
    assert_includes html, 'data-layout="plain"'
    refute_match(/<img/, html)
    assert_includes html, "Words only"
  end
end
