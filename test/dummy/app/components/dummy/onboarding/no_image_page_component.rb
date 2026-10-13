# frozen_string_literal: true

module Dummy
  module Onboarding
    class NoImagePageComponent < RecordingStudioOnboarding::PageComponent
      def initialize(run:, step:)
        super(
          run: run,
          step: step,
          title: "Just the words",
          content: "<p>No splash, no top card — title and HTML content only. Quiet and clear.</p>"
        )
      end
    end
  end
end
