# frozen_string_literal: true

module Dummy
  module Onboarding
    # Wide welcome card — uses the default PageComponent splash layout.
    class WelcomeComponent < RecordingStudioOnboarding::PageComponent
      def initialize(run:, step:)
        super(
          run: run,
          step: step,
          title: "Welcome aboard",
          content: "<p>A wide first step — set up your account in a few minutes.</p>",
          splash_image_url: DemoImage::URL
        )
      end
    end
  end
end
