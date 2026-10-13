# frozen_string_literal: true

# Public demo launcher for layout gallery screenshots (desktop + mobile review).
class OnboardingDemosController < ApplicationController
  VARIANTS = {
    "splash" => :splash,
    "top-card" => :top_card,
    "no-image" => :no_image,
    "buttons-left" => :buttons_left,
    "buttons-right" => :buttons_right,
    "buttons-full" => :buttons_full
  }.freeze

  def index
    @variants = VARIANTS.keys
  end

  def show
    step_key = VARIANTS.fetch(params[:variant]) do
      raise ActionController::RoutingError, "Unknown onboarding demo"
    end

    run = RecordingStudioOnboarding.start(:layout_gallery, actor: current_user)
    move_to!(run, step_key)
    redirect_to recording_studio_onboarding.run_path(run)
  end

  private

  def move_to!(run, step_key) # rubocop:disable Metrics/MethodLength
    keys = run.definition.step_keys
    target_index = keys.index(step_key)
    raise ActionController::RoutingError, "Unknown step" unless target_index

    rewind_if_past!(run, keys, target_index)
    advance_until!(run, keys, step_key, target_index)
  end

  def rewind_if_past!(run, keys, target_index)
    current_index = keys.index(run.current_step_key.to_sym)
    return unless current_index && current_index > target_index

    RecordingStudioOnboarding.reset(run, actor: current_user)
    run.reload
  end

  def advance_until!(run, keys, step_key, target_index)
    while run.reload.current_step_key.to_sym != step_key && run.open?
      current = run.current_step_key.to_sym
      index = keys.index(current)
      break if index.nil? || index >= target_index

      if run.current_step.skippable?
        RecordingStudioOnboarding.skip(run, from: current, actor: current_user)
      else
        RecordingStudioOnboarding.advance(run, from: current, actor: current_user)
      end
    end
  end
end
