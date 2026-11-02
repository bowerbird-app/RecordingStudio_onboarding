# frozen_string_literal: true

module RecordingStudioOnboarding
  # Raised after a provisioner handler fails and the execution row is marked failed.
  class ProvisionFailed < StandardError
    attr_reader :execution

    def initialize(error, execution:)
      @execution = execution
      super("#{error.class}: #{error.message}")
      set_backtrace(error.backtrace)
    end
  end
end
