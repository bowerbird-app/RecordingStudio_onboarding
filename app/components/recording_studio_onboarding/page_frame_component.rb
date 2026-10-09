# frozen_string_literal: true

module RecordingStudioOnboarding
  # Single shared content width for admin, previews, and user-facing step pages.
  class PageFrameComponent < ViewComponent::Base
    CONTAINER_CLASSES = "mx-auto w-full max-w-3xl px-4 py-6 sm:px-8 sm:py-8"

    def call
      content_tag(:div, content, class: CONTAINER_CLASSES, data: { testid: "onboarding-page-frame" })
    end
  end
end
