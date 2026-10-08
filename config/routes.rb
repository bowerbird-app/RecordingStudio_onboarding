# frozen_string_literal: true

RecordingStudioOnboarding::Engine.routes.draw do
  resources :runs, only: [:show], param: :uuid do
    member do
      post :advance
      post :back
      post :skip
      post :dismiss
    end
  end

  namespace :admin do
    get "previews/:flow_key/:step_key", to: "previews#show", as: :preview
    resources :runs, only: [:show], param: :uuid do
      member do
        post :reset
        post :restart
      end
    end
    resources :provisioning_executions, only: [:show] do
      member do
        post :retry
      end
    end
  end
end
