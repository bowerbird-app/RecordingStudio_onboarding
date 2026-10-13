# frozen_string_literal: true

module Dummy
  module Onboarding
    class ButtonsRightPageComponent < RecordingStudioOnboarding::PageComponent
      def initialize(run:, step:)
        super(
          run: run,
          step: step,
          title: "Continue on the right",
          content: "<p>Bottom Continue hugs the right edge. Useful when the primary action should lead.</p>"
        )
      end
    end
  end
end
