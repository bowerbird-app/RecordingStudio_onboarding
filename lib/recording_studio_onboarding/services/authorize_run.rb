# frozen_string_literal: true

module RecordingStudioOnboarding
  module Services
    # Default and custom run authorisation. Unauthorised callers see 404.
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

        policy = RecordingStudioOnboarding.configuration.authorize_run
        return policy.call(@run, @actor) if policy.respond_to?(:call)

        default_authorized?
      end

      private

      def default_authorized?
        definition = @run.definition
        return false if definition.nil?

        case definition.scope
        when :user
          same_record?(@run.scope, @actor)
        when :workspace, :subject
          accessible_to_actor?(@run.scope)
        else
          false
        end
      end

      def accessible_to_actor?(record)
        return false unless defined?(RecordingStudioAccessible)
        return false if record.nil?

        recording = recording_for(record)
        return false if recording.nil?

        RecordingStudioAccessible.authorized?(actor: @actor, recording: recording, role: :view)
      end

      def recording_for(record)
        if record.is_a?(RecordingStudio::Recording)
          record
        elsif defined?(RecordingStudio) && RecordingStudio.root_allowed?(record)
          RecordingStudio.root_recording_for(record)
        else
          RecordingStudio::Recording.find_by(recordable: record)
        end
      rescue StandardError
        nil
      end

      def same_record?(left, right)
        return false if left.nil? || right.nil?

        left.class.base_class == right.class.base_class && left.id == right.id
      end
    end
  end
end
