# frozen_string_literal: true

module Dummy
  module Onboarding
    class TopCardPageComponent < RecordingStudioOnboarding::PageComponent
      def initialize(run:, step:)
        super(
          run: run,
          step: step,
          title: "A photo up top, details below",
          content: "<p>The image sits in a top card with rounded corners. Title and copy follow.</p>",
          image_url: "/demos/onboarding/top-card.jpg"
        )
      end
    end
  end
end
