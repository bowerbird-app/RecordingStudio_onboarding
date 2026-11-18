# frozen_string_literal: true

RecordingStudioOnboarding.configure do |config|
  # Register host provisioners. Handlers must respond to .call.
  #
  # config.provision :new_registration,
  #   with: "MyApp::ProvisionRegistration"

  # config.checklist :studio do
  #   scope :user
  #   item :profile,
  #     check: ->(actor, _scope) { actor.email.present? },
  #     next_step: "Confirm the email on your account",
  #     link: "https://example.com/profile"
  # end
end
