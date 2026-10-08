# frozen_string_literal: true

require "test_helper"
require "recording_studio_onboarding/services/funnel_analytics"

class FunnelAnalyticsTest < ActiveSupport::TestCase
  setup do
    RecordingStudioOnboarding.configure do |config|
      config.instance_variable_get(:@flows).delete(:funnel_demo)
      config.flow :funnel_demo do
        scope :user
        version 1
        dismissible true
        step :a, component: "Dummy::Onboarding::WelcomeComponent"
        step :b, component: "Dummy::Onboarding::WorkspaceDetailsComponent"
        step :c, component: "Dummy::Onboarding::CompleteComponent"
      end
    end
  end

  test "computes funnel metrics from FlowRun and StepProgress" do
    actor = User.create!(
      email: "funnel-#{SecureRandom.hex(4)}@example.com",
      password: "Password",
      password_confirmation: "Password"
    )
    run = RecordingStudioOnboarding.start(:funnel_demo, actor: actor)
    RecordingStudioOnboarding.mark_viewed(run, actor: actor)
    RecordingStudioOnboarding.advance(run, from: "a", actor: actor)
    run.reload
    RecordingStudioOnboarding.mark_viewed(run, actor: actor)
    RecordingStudioOnboarding.dismiss(run, actor: actor)

    actor2 = User.create!(
      email: "funnel2-#{SecureRandom.hex(4)}@example.com",
      password: "Password",
      password_confirmation: "Password"
    )
    run2 = RecordingStudioOnboarding.start(:funnel_demo, actor: actor2)
    %w[a b c].each do |key|
      run2.reload
      RecordingStudioOnboarding.mark_viewed(run2, actor: actor2)
      RecordingStudioOnboarding.advance(run2, from: key, actor: actor2)
    end

    summary = RecordingStudioOnboarding::Services::FunnelAnalytics.call(flow_key: :funnel_demo)

    assert_equal 2, summary.total_runs
    assert_equal 1, summary.completed
    assert_equal 1, summary.dismissed
    assert_in_delta 50.0, summary.completion_rate, 0.1
    assert_in_delta 50.0, summary.dismissal_rate, 0.1

    step_a = summary.steps.find { |row| row.step_key == "a" }
    step_b = summary.steps.find { |row| row.step_key == "b" }
    assert_equal 2, step_a.reached
    assert_equal 2, step_b.reached
    assert_equal 1, step_b.dismissals
  end
end
