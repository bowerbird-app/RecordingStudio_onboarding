# frozen_string_literal: true

module Dummy
  module Onboarding
    class SplashPageComponent < RecordingStudioOnboarding::PageComponent
      def initialize(run:, step:)
        super(
          run: run,
          step: step,
          title: "Make your first workspace feel like home",
          content: "<p>Full-bleed splash with a soft tint so the words stay readable.</p>",
          splash_image_url: DemoImage::URL,
          image_url: DemoImage::URL
        )
      end
    end
  end
end
