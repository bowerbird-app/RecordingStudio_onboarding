# frozen_string_literal: true

module RecordingStudioOnboarding
  class ApplicationController < (defined?(::ApplicationController) ? ::ApplicationController : ActionController::Base)
    protect_from_forgery with: :exception
    helper RecordingStudioOnboarding::ApplicationHelper

    private

    def current_onboarding_actor
      resolver = RecordingStudioOnboarding.configuration.current_actor
      if resolver.respond_to?(:call)
        resolver.call(self)
      elsif respond_to?(:current_user)
        current_user
      elsif defined?(Current) && Current.respond_to?(:actor)
        Current.actor
      end
    end
  end
end
