# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require_relative "../config/environment"
require "rails/test_help"

OmniAuth.config.test_mode = true

module TermsAcceptanceTestSupport
  # Ordinary integration tests should not be blocked by the soft Terms gate.
  # Opt out with Thread.current[:leave_terms_pending] = true (see terms-gate tests).
  def accept_live_terms_for_tests!(actor)
    return unless defined?(RecordingStudioTermsAndConditions)
    return if actor.blank?
    return if Thread.current[:leave_terms_pending]

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

module AutoAcceptTermsOnSignIn
  def sign_in(resource, *args, **kwargs)
    accept_live_terms_for_tests!(resource)
    super
  end
end

class ActionDispatch::IntegrationTest
  include TermsAcceptanceTestSupport
  prepend AutoAcceptTermsOnSignIn

  def self.inherited(subclass)
    super
    subclass.prepend(AutoAcceptTermsOnSignIn)
  end
end
