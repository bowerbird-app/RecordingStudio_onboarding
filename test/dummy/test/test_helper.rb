# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require_relative "../config/environment"
require "rails/test_help"

OmniAuth.config.test_mode = true

module TermsAcceptanceTestSupport
  # Ordinary integration tests should not be blocked by the soft Terms gate.
  # Call this before sign_in in tests that should pass the gate.
  def accept_live_terms_for_tests!(actor)
    return unless defined?(RecordingStudioTermsAndConditions)
    return if actor.blank?

    RecordingStudio::Recording.where(parent_recording_id: nil).find_each do |root_recording|
      root = root_recording.recordable
      next if root.blank?

      RecordingStudioTermsAndConditions.pending_published_list(actor, root).each do |terms|
        RecordingStudioTermsAndConditions.accept!(actor, terms, { "source" => "test" })
      end
    rescue StandardError
      # Roots without live Terms or missing Publishable tables are fine.
    end
  end
end

module OnboardingActorTestSupport
  def with_actor(actor)
    previous = Current.actor
    Current.actor = actor
    yield
  ensure
    Current.actor = previous
  end
end

class ActionDispatch::IntegrationTest
  include TermsAcceptanceTestSupport
  include OnboardingActorTestSupport
end
