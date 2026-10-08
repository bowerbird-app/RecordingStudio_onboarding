# frozen_string_literal: true

module RecordingStudioOnboarding
  module Services
    # Resolves the persisted scope record for a flow definition.
    class ScopeResolver
      def self.call(...)
        new(...).call
      end

      def initialize(definition, actor:, subject: nil)
        @definition = definition
        @actor = actor
        @subject = subject
      end

      def call # rubocop:disable Metrics/MethodLength
        case @definition.scope
        when :user
          raise ArgumentError, "actor is required for user-scoped flows" if @actor.nil?

          @actor
        when :workspace
          resolve_workspace
        when :subject
          raise ArgumentError, "subject is required for subject-scoped flows" if @subject.nil?

          @subject
        else
          raise ArgumentError, "Unsupported scope #{@definition.scope.inspect}"
        end
      end

      private

      def resolve_workspace
        raise ArgumentError, "subject (workspace) is required for workspace-scoped flows" if @subject.nil?

        unless root_recordable?(@subject)
          raise ArgumentError, "workspace-scoped flows require a root recordable subject"
        end

        @subject
      end

      def root_recordable?(record)
        return false unless defined?(RecordingStudio)

        RecordingStudio.root_allowed?(record)
      end
    end
  end
end
