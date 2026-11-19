# frozen_string_literal: true

require "recording_studio_onboarding/services/accessible_authorization"
require "recording_studio_onboarding/services/enqueue_setup_recheck"
require "recording_studio_onboarding/services/refresh_setup_status"
require "recording_studio_onboarding/services/scope_resolver"

module RecordingStudioOnboarding
  module Services
    # Fast path for `setup_status`. A missing row is computed inline.
    class ReadSetupStatus
      def self.call(name, actor:, subject: nil)
        new(name, actor: actor, subject: subject).call
      end

      def initialize(name, actor:, subject:)
        @name = name.to_sym
        @actor = actor
        @subject = subject
      end

      def call
        definition = definition_for
        scope = ScopeResolver.call(definition, actor: @actor, subject: @subject)
        authorize!(definition, scope)
        row = SetupCheck.find_by(checklist_key: definition.key.to_s, actor: @actor, scope: scope)
        return refresh if row.nil?

        EnqueueSetupRecheck.call(definition.key, @actor, scope)
        SetupSnapshot.load(definition, row)
      end

      private

      def definition_for
        definition = RecordingStudioOnboarding.configuration.checklist_for(@name)
        raise KeyError, "No checklist registered for #{@name.inspect}" unless definition

        definition
      end

      def authorize!(definition, scope)
        return if AccessibleAuthorization.allowed_for_scope?(definition: definition, scope: scope, actor: @actor)

        raise Unauthorized, "not authorized for this checklist"
      end

      def refresh
        RefreshSetupStatus.call(@name, actor: @actor, subject: @subject)
      end
    end
  end
end
