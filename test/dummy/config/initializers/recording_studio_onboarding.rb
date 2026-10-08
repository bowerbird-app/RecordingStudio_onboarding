# frozen_string_literal: true

RecordingStudioOnboarding.configure do |config|
  config.provision :new_registration, with: "Dummy::ProvisionRegistration"
  config.current_actor = ->(controller) { controller.current_user }

  config.flow :account_setup do
    scope :user
    progress :segments
    dismissible true
    version 1
    after_complete "/"
    after_dismiss "/flows"
    step :welcome,
      component: "Dummy::Onboarding::WelcomeComponent",
      controls: %i[continue exit],
      show_progress: true
    step :workspace_details,
      component: "Dummy::Onboarding::WorkspaceDetailsComponent",
      controls: %i[back skip exit],
      skippable: true
    step :complete,
      component: "Dummy::Onboarding::CompleteComponent",
      controls: %i[continue],
      show_progress: false
  end

  config.flow :workspace_setup do
    scope :workspace
    progress :bar
    dismissible false
    version 1
    after_complete "/"
    after_dismiss "/"
    step :name_workspace,
      component: "Dummy::Onboarding::NameWorkspaceComponent",
      controls: %i[continue]
    step :invite_teammate,
      component: "Dummy::Onboarding::InviteTeammateComponent",
      controls: %i[back continue skip],
      skippable: true
  end

  config.flow :first_presskit do
    scope :subject
    progress :segments
    dismissible true
    version 1
    after_complete "/"
    after_dismiss "/flows"
    step :introduction,
      component: "Dummy::Onboarding::PresskitIntroductionComponent",
      controls: %i[continue exit]
    step :add_images,
      component: "Dummy::Onboarding::AddImagesComponent",
      controls: %i[back continue],
      complete_when: ->(run) { run.scope.respond_to?(:title) && run.scope.title.to_s.include?("ready") }
    step :publish,
      component: "Dummy::Onboarding::PublishComponent",
      controls: %i[back continue]
  end
end
