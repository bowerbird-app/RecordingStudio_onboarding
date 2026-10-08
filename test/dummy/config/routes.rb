# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }

  # RecordingStudio engine is data/API-focused and has no browser root route.
  # Keep legacy links working by redirecting the base path to the app home.
  get "/recording_studio", to: redirect("/"), as: nil
  mount RecordingStudio::Engine, at: "/recording_studio"
  mount RecordingStudioRootSwitchable::Engine, at: "/recording_studio_root_switchable"
  mount RecordingStudioOnboarding::Engine, at: "/onboarding"

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

  resources :flow_runs, only: [:show] do
    member do
      post :advance
      post :back
      post :skip
      post :dismiss
      post :reset
    end
  end

  root "home#index"
end
