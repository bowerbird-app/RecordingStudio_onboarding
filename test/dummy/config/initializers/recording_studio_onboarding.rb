# frozen_string_literal: true

RecordingStudioOnboarding.configure do |config|
  config.provision :new_registration, with: "Dummy::ProvisionRegistration"
end
