# frozen_string_literal: true

module RecordingStudioOnboarding
  module Services
    # Scrubs credentials and other sensitive values from failure diagnostics.
    module FailureSanitizer
      SENSITIVE_KEY = /
        password|passwd|secret|token|api[_-]?key|authorization|credential|
        private[_-]?key|access[_-]?key|refresh[_-]?token|client[_-]?secret
      /xi

      SENSITIVE_ASSIGNMENT = /
        (#{SENSITIVE_KEY.source})\s*[:=]\s*([^\s,;]+)
      /xi

      module_function

      def call(error)
        message = "#{error.class}: #{error.message}"
        scrub(message)
      end

      def scrub(text)
        text.to_s.gsub(SENSITIVE_ASSIGNMENT) do
          "#{Regexp.last_match(1)}=[FILTERED]"
        end
      end
    end
  end
end
