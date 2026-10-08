# frozen_string_literal: true

module RecordingStudioOnboarding
  # Base for host/dummy step cards. Subclasses own internal layout.
  class BaseCardComponent < ViewComponent::Base
    attr_reader :run, :step

    def initialize(run:, step:)
      super()
      @run = run
      @step = step
    end
  end
end
