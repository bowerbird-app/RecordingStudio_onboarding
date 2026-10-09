# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users,
             skip: %i[sessions registrations passwords],
             controllers: {
               confirmations: "recording_studio_user/auth/confirmations",
               omniauth_callbacks: "recording_studio_user/omniauth_callbacks"
             }

  recording_studio_user_auth_for :users

  # RecordingStudio engine is data/API-focused and has no browser root route.
  # Keep legacy links working by redirecting the base path to the app home.
  get "/recording_studio", to: redirect("/"), as: nil
  mount RecordingStudio::Engine, at: "/recording_studio"
  mount RecordingStudioRootSwitchable::Engine, at: "/recording_studio_root_switchable"
  mount RecordingStudioOnboarding::Engine, at: "/onboarding"
  mount RecordingStudioAccessible::Engine, at: "/admin/access"
  mount RecordingStudioAttachable::Engine, at: "/recording_studio_attachable"
  mount RecordingStudioTermsAndConditions::Engine, at: "/recording_studio_terms_and_conditions"
  mount RecordingStudioPublishable::Engine, at: "/", as: :recording_studio_publishable
  mount RecordingStudioUser::Engine => RecordingStudioUser.config.mount_path, as: :recording_studio_users
  namespace :admin do
    get "root", to: "root#show", as: :root
  end
  recording_studio_admin_for :admin, at: "/admin", root_section: :root

  get "up" => "rails/health#show", as: :rails_health_check

  get "docs/install", to: "docs#install", as: :docs_install
  get "docs/config", to: "docs#configuration", as: :docs_config
  get "docs/recordable_types", to: "docs#recordable_types", as: :docs_recordable_types
  get "docs/recordings_tree", to: "docs#recordings_tree", as: :docs_recordings_tree
  get "docs/gem_views", to: "docs#gem_views", as: :docs_gem_views
  get "docs/methods", to: "docs#methods", as: :docs_methods

  get "provisioning", to: "provisioning#show", as: :provisioning

  resources :flows, only: [:index] do
    collection do
      post :start
    end
  end

  # Host form endpoints for onboarding cards (§16).
  post "onboarding_forms/workspace_details",
       to: "onboarding_forms#workspace_details",
       as: :onboarding_workspace_details
  post "onboarding_forms/presskit_images",
       to: "onboarding_forms#presskit_images",
       as: :onboarding_presskit_images

  # PR 2 flow_runs demo folded into engine routes.
  get "flow_runs/:id", to: redirect { |params, _req| "/onboarding/runs/#{params[:id]}" }

  root "home#index"
end
