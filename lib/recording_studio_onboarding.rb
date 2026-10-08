# frozen_string_literal: true

require "recording_studio"
require "recording_studio_onboarding/version"
require "recording_studio_onboarding/engine"
require "recording_studio_onboarding/configuration"
require "recording_studio_onboarding/services/failure_sanitizer"
require "recording_studio_onboarding/users_registration_integration"

module RecordingStudioOnboarding
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
      configuration
    end

    # Execute a registered provisioner immediately with idempotent tracking.
    #
    #   RecordingStudioOnboarding.provision(
    #     :new_registration,
    #     actor: user,
    #     subject: user
    #   )
    def provision(name, **)
      require "recording_studio_onboarding/services/provision"
      Services::Provision.call(name, **)
    end
  end
end
