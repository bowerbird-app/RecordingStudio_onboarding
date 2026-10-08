# frozen_string_literal: true

module RecordingStudioOnboarding
  module ApplicationHelper
    # Cards render controls through this helper — never build navigation URLs locally.
    def onboarding_controls(run, **)
      render RecordingStudioOnboarding::ControlsComponent.new(run: run, **)
    end

    def onboarding_progress(run, **)
      render RecordingStudioOnboarding::ProgressComponent.new(run: run, **)
    end
  end
end
