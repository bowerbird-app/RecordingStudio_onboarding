# frozen_string_literal: true

require "recording_studio_onboarding/services/accessible_authorization"

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
        authorize_scope!(definition, scope)
        find_or_create_run!(definition, scope)
      end

      private

      def authorize_scope!(definition, scope)
        return if AccessibleAuthorization.allowed_for_scope?(
          definition: definition,
          scope: scope,
          actor: @actor
        )

        raise RecordingStudioOnboarding::Unauthorized, "not authorized for this flow"
      end

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

      def create_run!(definition, scope)
        run = insert_run_and_steps!(definition, scope)
        Instrumenter.instrument("flow.started", Instrumenter.flow_payload(run, actor: @actor))
        run
      end

      def insert_run_and_steps!(definition, scope)
        run = nil
        ActiveRecord::Base.transaction(requires_new: true) do
          run = FlowRun.create!(run_attributes(definition, scope))
          definition.step_keys.each do |key|
            StepProgress.create!(flow_run: run, step_key: key.to_s, status: "pending")
          end
        end
        run
      end

      def run_attributes(definition, scope)
        {
          flow_key: definition.key.to_s,
          flow_version: definition.version,
          scope: scope,
          initiating_actor: @actor,
          status: "in_progress",
          current_step_key: definition.first_step_key.to_s,
          started_at: Time.current
        }
      end
    end
  end
end
