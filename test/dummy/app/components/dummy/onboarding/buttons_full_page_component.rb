# frozen_string_literal: true

module Dummy
  module Onboarding
    class ButtonsFullPageComponent < RecordingStudioOnboarding::PageComponent
      def initialize(run:, step:)
        super(
          run: run,
          step: step,
          title: "Full-width Continue",
          content: "<p>One big Continue across the bottom. Easy to tap on a phone.</p>"
        )
      end
    end
  end
end
