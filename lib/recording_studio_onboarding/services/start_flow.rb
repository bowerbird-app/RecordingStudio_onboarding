# frozen_string_literal: true

module RecordingStudioOnboarding
  module Services
    class StartFlow
      def self.call(...)
        new(...).call
      end

      def initialize(name, actor:, subject: nil)
        @name = name.to_sym
        @actor = actor
        @subject = subject
      end

      def call
        raise ArgumentError, "actor is required" if @actor.nil?

        definition = RecordingStudioOnboarding.configuration.flow_for(@name)
        raise KeyError, "No flow registered for #{@name.inspect}" unless definition

        scope = ScopeResolver.call(definition, actor: @actor, subject: @subject)
        find_or_create_run!(definition, scope)
      end

      private

      def find_or_create_run!(definition, scope)
        existing = FlowRun.open_runs.find_by(
          flow_key: definition.key.to_s,
          scope: scope
        )
        return ReconcileRun.call(existing) if existing

        create_run!(definition, scope)
      rescue ActiveRecord::RecordNotUnique
        FlowRun.open_runs.find_by!(flow_key: definition.key.to_s, scope: scope).tap do |run|
          ReconcileRun.call(run)
        end
      end

      def create_run!(definition, scope) # rubocop:disable Metrics/MethodLength
        run = nil
        # requires_new so a uniqueness conflict rolls back to a savepoint and
        # leaves an outer (test) transaction usable for the find retry.
        ActiveRecord::Base.transaction(requires_new: true) do
          run = FlowRun.create!(
            flow_key: definition.key.to_s,
            flow_version: definition.version,
            scope: scope,
            initiating_actor: @actor,
            status: "in_progress",
            current_step_key: definition.first_step_key.to_s,
            started_at: Time.current
          )
          definition.step_keys.each do |key|
            StepProgress.create!(flow_run: run, step_key: key.to_s, status: "pending")
          end
        end

        Instrumenter.instrument("flow.started", Instrumenter.flow_payload(run, actor: @actor))
        run
      end
    end
  end
end
