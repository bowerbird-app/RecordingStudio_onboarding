# frozen_string_literal: true

class FlowRunsController < ApplicationController
  before_action :set_run

  def show
    RecordingStudioOnboarding.mark_viewed(@run, actor: current_user)
    @run.reload
    @definition = @run.definition
    @steps = @run.step_progresses.order(:created_at)
  end

  def advance
    RecordingStudioOnboarding.advance(@run, from: params[:from], actor: current_user)
    redirect_to flow_run_path(@run)
  end

  def back
    RecordingStudioOnboarding.back(@run, from: params[:from], actor: current_user)
    redirect_to flow_run_path(@run)
  end

  def skip
    RecordingStudioOnboarding.skip(@run, from: params[:from], actor: current_user)
    redirect_to flow_run_path(@run)
  rescue ArgumentError => e
    redirect_to flow_run_path(@run), alert: e.message
  end

  def dismiss
    RecordingStudioOnboarding.dismiss(@run, actor: current_user)
    redirect_to flows_path, notice: "Dismissed #{@run.flow_key}"
  end

  def reset
    RecordingStudioOnboarding.reset(@run, actor: current_user)
    redirect_to flow_run_path(@run), notice: "Reset #{@run.flow_key}"
  end

  private

  def set_run
    @run = RecordingStudioOnboarding::FlowRun.find(params[:id])
  end
end
