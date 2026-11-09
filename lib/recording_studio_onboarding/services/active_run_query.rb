# frozen_string_literal: true

require "recording_studio_onboarding/services/accessible_authorization"

module RecordingStudioOnboarding
  module Services
    class ActiveRunQuery
      def self.call(...)
        new(...).call
      end

      def initialize(name, actor:, subject: nil)
        @name = name.to_sym
        @actor = actor
        @subject = subject
      end

      def call
        definition = RecordingStudioOnboarding.configuration.flow_for(@name)
        return if definition.nil? || @actor.nil?

        scope = ScopeResolver.call(definition, actor: @actor, subject: @subject)
        return unless scope_allowed?(definition, scope)

        run = FlowRun.open_runs.find_by(flow_key: definition.key.to_s, scope: scope)
        return unless run

        ReconcileRun.call(run)
      end

      private

      def scope_allowed?(definition, scope)
        AccessibleAuthorization.allowed_for_scope?(
          definition: definition,
          scope: scope,
          actor: @actor
        )
      end
    end
  end
end
