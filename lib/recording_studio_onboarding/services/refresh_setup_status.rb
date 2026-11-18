# frozen_string_literal: true

require "recording_studio_onboarding/services/evaluate_checklist"
require "recording_studio_onboarding/setup_snapshot"
require "recording_studio_onboarding/services/scope_resolver"
require "recording_studio_onboarding/services/instrumenter"

module RecordingStudioOnboarding
  module Services
    class RefreshSetupStatus
      def self.call(name, actor:, subject: nil, throttle: false)
        new(name, actor: actor, subject: subject, throttle: throttle).call
      end

      def initialize(name, actor:, subject:, throttle:)
        @name = name.to_sym
        @actor = actor
        @subject = subject
        @throttle = throttle
      end

      def call
        definition = definition_for
        scope = ScopeResolver.call(definition, actor: @actor, subject: @subject)
        return remembered(definition, scope) if skip_write?(definition, scope)

        status = EvaluateChecklist.call(definition, actor: @actor, scope: scope)
        previous, checked_at = write(definition, scope, status)
        emit(definition, scope, previous, status.complete)
        status.with(checked_at: checked_at)
      end

      private

      def definition_for
        definition = RecordingStudioOnboarding.configuration.checklist_for(@name)
        raise KeyError, "No checklist registered for #{@name.inspect}" unless definition

        definition
      end

      def skip_write?(definition, scope)
        @throttle && fresh?(saved_row(definition, scope))
      end

      def fresh?(row)
        return false if row.nil? || row.checked_at.nil?

        row.checked_at > Time.current - RecordingStudioOnboarding.configuration.setup_recheck_interval
      end

      def remembered(definition, scope)
        SetupSnapshot.load(definition, saved_row(definition, scope))
      end

      def saved_row(definition, scope)
        SetupCheck.find_by(checklist_key: definition.key.to_s, actor: @actor, scope: scope)
      end

      def write(definition, scope, status)
        SetupCheck.transaction do
          row = SetupCheck.lock.find_by(checklist_key: definition.key.to_s, actor: @actor, scope: scope)
          row ||= SetupCheck.new(checklist_key: definition.key.to_s, actor: @actor, scope: scope)
          previous = row.persisted? ? row.complete : nil
          row.update!(row_attributes(status))
          [previous, row.checked_at]
        end
      rescue ActiveRecord::RecordNotUnique
        replace(definition, scope, status)
      end

      def replace(definition, scope, status)
        row = saved_row(definition, scope)
        previous = row.complete
        row.update!(row_attributes(status))
        [previous, row.checked_at]
      end

      def row_attributes(status)
        {
          applicable: status.applicable,
          complete: status.complete,
          items: SetupSnapshot.dump(status),
          checked_at: Time.current
        }
      end

      def emit(definition, scope, previous, complete)
        name = event_name(previous, complete)
        return if name.nil?

        Instrumenter.instrument(name, event_payload(definition, scope, complete))
      end

      def event_name(previous, complete)
        return "setup.completed" if complete && previous != true
        return "setup.regressed" if previous == true && !complete

        nil
      end

      def event_payload(definition, scope, complete)
        {
          checklist_key: definition.key.to_s,
          actor_type: @actor.class.base_class.name,
          actor_id: @actor.id,
          scope_type: scope.class.base_class.name,
          scope_id: scope.id,
          complete: complete
        }
      end
    end
  end
end
