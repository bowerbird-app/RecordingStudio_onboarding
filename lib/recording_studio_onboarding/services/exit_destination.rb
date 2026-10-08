# frozen_string_literal: true

module RecordingStudioOnboarding
  module Services
    # Resolves after_complete / after_dismiss destinations for a finished run.
    class ExitDestination
      def self.call(...)
        new(...).call
      end

      def initialize(run, kind:)
        @run = run
        @kind = kind.to_sym
      end

      def call
        definition = @run.definition
        configured =
          case @kind
          when :complete then definition&.after_complete
          when :dismiss then definition&.after_dismiss
          end

        resolve(configured)
      end

      private

      def resolve(configured)
        return "/" if configured.nil?
        return configured.to_s if configured.is_a?(String) || configured.is_a?(Symbol)
        return configured.call(@run).presence || "/" if configured.respond_to?(:call)

        "/"
      end
    end
  end
end
