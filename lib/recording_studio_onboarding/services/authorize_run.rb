# frozen_string_literal: true

require "recording_studio_onboarding/services/accessible_authorization"

module RecordingStudioOnboarding
  module Services
    # Default Accessible authorisation, plus an optional extra-deny host policy.
    # Unauthorised callers see 404. A custom policy cannot widen past Accessible.
    class AuthorizeRun
      def self.call(...)
        new(...).call
      end

      def initialize(run, actor:)
        @run = run
        @actor = actor
      end

      def call
        return false if @actor.nil? || @run.nil?
        return false unless default_authorized?

        policy = RecordingStudioOnboarding.configuration.authorize_run
        return true unless policy.respond_to?(:call)

        policy.call(@run, @actor)
      end

      private

      def default_authorized?
        AccessibleAuthorization.allowed_for_scope?(
          definition: @run.definition,
          scope: @run.scope,
          actor: @actor
        )
      end
    end
  end
end
