# frozen_string_literal: true

require "active_job"

module RecordingStudioOnboarding
  # Corrects a saved setup check after the fast path or a sign-in.
  class RecheckSetupJob < ActiveJob::Base
    queue_as :default

    def perform(checklist_key, actor_gid, scope_gid)
      actor = locate(actor_gid)
      scope = locate(scope_gid)
      return if actor.nil? || scope.nil?

      Services::RefreshSetupStatus.call(checklist_key, actor: actor, subject: scope, throttle: true)
    rescue KeyError, ArgumentError
      nil
    end

    private

    def locate(gid)
      GlobalID::Locator.locate(gid)
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
end
