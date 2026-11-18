# frozen_string_literal: true

module RecordingStudioOnboarding
  # Single shared content width for admin, previews, and user-facing step pages.
  class PageFrameComponent < ViewComponent::Base
    CONTAINER_STYLE = "margin-inline: auto; width: 100%; max-width: 48rem; " \
                      "padding: var(--space-6) var(--space-4);"

    def call
      content_tag(:div, content, style: CONTAINER_STYLE, data: { testid: "onboarding-page-frame" })
    end
  end
end
