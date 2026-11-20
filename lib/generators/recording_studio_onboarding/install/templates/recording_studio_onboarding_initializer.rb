# frozen_string_literal: true

RecordingStudioOnboarding.configure do |config|
  # Register host provisioners. Handlers must respond to .call.
  #
  # config.provision :new_registration,
  #   with: "MyApp::ProvisionRegistration"
  #
  # Leave false unless the handler only enqueues a job. See the README.
  # config.provision_async = false

  # config.checklist :studio do
  #   scope :user
  #   item :profile,
  #     check: ->(actor, _scope) { actor.email.present? },
  #     next_step: "Confirm the email on your account",
  #     link: -> { main_app.new_press_kit_path },
  #     icon: :queue_list
  # end
end
