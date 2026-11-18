# frozen_string_literal: true

module RecordingStudioOnboarding
  class SetupPageComponent < ViewComponent::Base
    attr_reader :status

    def initialize(status:, heading: true)
      super()
      @status = status
      @heading = heading
    end

    def heading?
      @heading
    end

    def title
      "Your setup"
    end

    def subtitle
      return "Nothing here applies to you." unless status.applicable?
      return "You're all set." if status.complete?

      "What to do next."
    end
  end
end
