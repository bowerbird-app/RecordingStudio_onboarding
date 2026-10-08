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
end
