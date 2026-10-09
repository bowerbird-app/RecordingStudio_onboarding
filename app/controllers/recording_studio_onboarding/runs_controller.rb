# frozen_string_literal: true

module RecordingStudioOnboarding
  class RunsController < ApplicationController
    before_action :require_actor!
    before_action :set_run
    before_action :authorize_run!
    before_action :defer_before_onboarding_gates!

    layout :resolve_layout

    def show
      RecordingStudioOnboarding.mark_viewed(@run, actor: current_onboarding_actor)
      @run.reload
      return redirect_finished! unless @run.open?

      render_run
    end

    def advance
      RecordingStudioOnboarding.advance(@run, from: params[:from], actor: current_onboarding_actor)
      after_transition!
    end

    def back
      RecordingStudioOnboarding.back(@run, from: params[:from], actor: current_onboarding_actor)
      after_transition!
    end

    def skip
      RecordingStudioOnboarding.skip(@run, from: params[:from], actor: current_onboarding_actor)
      after_transition!
    rescue ArgumentError => e
      redirect_to run_path(@run), alert: e.message
    end

    def dismiss
      RecordingStudioOnboarding.dismiss(@run, actor: current_onboarding_actor)
      @run.reload
      # Dismissible → dismissed + destination. Non-dismissible → leave screen, keep open.
      redirect_to exit_path_for(:dismiss)
    end

    private

    def set_run
      @run = FlowRun.find(params[:uuid] || params[:id])
    rescue ActiveRecord::RecordNotFound
      render_not_found
    end

    def require_actor!
      return if current_onboarding_actor.present?

      # Host Devise/RS Users auth should already redirect; fall back to 404.
      render_not_found
    end

    def authorize_run!
      return if performed?

      require "recording_studio_onboarding/services/authorize_run"
      return if Services::AuthorizeRun.call(@run, actor: current_onboarding_actor)

      render_not_found
    end

    def defer_before_onboarding_gates!
      return if performed?

      path = RecordingStudioOnboarding.before_onboarding_redirect_to(
        self,
        actor: current_onboarding_actor,
        return_path: request.fullpath
      )
      redirect_to path if path.present?
    end

    def render_not_found
      head :not_found
    end

    def after_transition!
      @run.reload
      return redirect_finished! unless @run.open?

      if turbo_frame_request?
        render_run
      else
        redirect_to run_path(@run)
      end
    end

    def redirect_finished!
      kind = @run.completed? ? :complete : :dismiss
      if turbo_frame_request?
        render_run
      else
        redirect_to exit_path_for(kind)
      end
    end

    def exit_path_for(kind)
      require "recording_studio_onboarding/services/exit_destination"
      Services::ExitDestination.call(@run, kind: kind)
    end

    def render_run
      @embedded = embedded_request?
      render :show, layout: resolve_layout
    end

    def embedded_request?
      turbo_frame_request? || params[:embedded].present?
    end

    def resolve_layout
      return false if embedded_request?

      "recording_studio_onboarding/card_shell"
    end

    def turbo_frame_request?
      request.headers["Turbo-Frame"].present?
    end
  end
end
