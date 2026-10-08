# frozen_string_literal: true

module Users
  # Host Devise registration override.
  #
  # RecordingStudio_users does not yet expose a public password/OAuth registration
  # hook, so the dummy host triggers provisioning explicitly after a new account
  # is persisted. Existing-user sign-in never reaches this controller.
  class RegistrationsController < Devise::RegistrationsController
    def create
      super do |resource|
        next unless resource.persisted?

        RecordingStudioOnboarding.provision(
          :new_registration,
          actor: resource,
          subject: resource,
          context: { source: "devise.registrations#create" }
        )
      end
    end
  end
end
