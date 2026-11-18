# frozen_string_literal: true

module RecordingStudioOnboarding
  # `self` for a zero-argument item `link` callable, so a host can write
  # `link: -> { main_app.new_press_kit_path }` from an initializer.
  module HostUrlContext
    def main_app
      Rails.application.routes.url_helpers
    end
    module_function :main_app
  end
end
