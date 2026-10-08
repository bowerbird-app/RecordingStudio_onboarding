# frozen_string_literal: true

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
        run = FlowRun.open_runs.find_by(flow_key: definition.key.to_s, scope: scope)
        return unless run

        ReconcileRun.call(run)
      end
    end
  end
end
