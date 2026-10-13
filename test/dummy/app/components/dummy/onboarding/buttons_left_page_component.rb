# frozen_string_literal: true

module Dummy
  module Onboarding
    class ButtonsLeftPageComponent < RecordingStudioOnboarding::PageComponent
      def initialize(run:, step:)
        super(
          run: run,
          step: step,
          title: "Continue on the left",
          content: "<p>Bottom Continue sits on the left. Back and Skip stay in the top chrome.</p>"
        )
      end
    end
  end
end
