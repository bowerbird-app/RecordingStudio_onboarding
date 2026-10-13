# frozen_string_literal: true

RecordingStudioOnboarding.configure do |config|
  config.provision :new_registration, with: "Dummy::ProvisionRegistration"
  config.current_actor = ->(controller) { controller.current_user }
  config.preview_context = lambda do |flow_key:, step_key:|
    {
      actor: User.find_by(email: "admin@admin.com") || User.first,
      subject: Workspace.find_by(name: "Studio Workspace") || Workspace.first,
      flow_key: flow_key,
      step_key: step_key
    }
  end

  config.flow :account_setup do
    scope :user
    progress :bar
    dismissible true
    version 1
    after_complete "/"
    after_dismiss "/flows"
    step :welcome,
      component: "Dummy::Onboarding::WelcomeComponent",
      controls: %i[continue],
      button_positions: { continue: :full },
      skippable: false,
      show_progress: true
    step :workspace_details,
      component: "Dummy::Onboarding::WorkspaceDetailsComponent",
      controls: %i[],
      skippable: true
    step :complete,
      component: "Dummy::Onboarding::CompleteComponent",
      controls: %i[continue],
      button_positions: { continue: :right },
      show_progress: false,
      skippable: false
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
      controls: %i[continue],
      button_positions: { continue: :left },
      skippable: false
    step :invite_teammate,
      component: "Dummy::Onboarding::InviteTeammateComponent",
      controls: %i[continue],
      button_positions: { continue: :right },
      skippable: true
  end

  config.flow :first_presskit do
    scope :subject
    progress :bar
    dismissible true
    version 1
    after_complete "/"
    after_dismiss "/flows"
    step :introduction,
      component: "Dummy::Onboarding::PresskitIntroductionComponent",
      controls: %i[continue],
      button_positions: { continue: :full },
      skippable: false
    step :add_images,
      component: "Dummy::Onboarding::AddImagesComponent",
      controls: %i[continue],
      complete_when: ->(run) { run.scope.respond_to?(:title) && run.scope.title.to_s.include?("ready") }
    step :publish,
      component: "Dummy::Onboarding::PublishComponent",
      controls: %i[continue],
      skippable: false
  end

  # Layout gallery for review screenshots — splash, top-card, plain, button positions.
  config.flow :layout_gallery do
    scope :user
    progress :bar
    dismissible false
    version 1
    after_complete "/demos/onboarding"
    after_dismiss "/demos/onboarding"
    step :splash,
      component: "Dummy::Onboarding::SplashPageComponent",
      controls: %i[continue],
      button_positions: { continue: :full },
      skippable: true
    step :top_card,
      component: "Dummy::Onboarding::TopCardPageComponent",
      controls: %i[continue],
      button_positions: { continue: :right },
      skippable: true
    step :no_image,
      component: "Dummy::Onboarding::NoImagePageComponent",
      controls: %i[continue],
      button_positions: { continue: :left },
      skippable: true
    step :buttons_left,
      component: "Dummy::Onboarding::ButtonsLeftPageComponent",
      controls: %i[continue],
      button_positions: { continue: :left },
      skippable: true
    step :buttons_right,
      component: "Dummy::Onboarding::ButtonsRightPageComponent",
      controls: %i[continue],
      button_positions: { continue: :right },
      skippable: true
    step :buttons_full,
      component: "Dummy::Onboarding::ButtonsFullPageComponent",
      controls: %i[continue],
      button_positions: { continue: :full },
      skippable: false
  end
end
