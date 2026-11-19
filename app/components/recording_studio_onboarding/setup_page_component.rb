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
      status.title
    end

    def subtitle
      status.subtitle
    end
  end
end
