# frozen_string_literal: true

# Host-owned form endpoints for onboarding cards (§16).
# The gem never persists workspace/page fields — the host does, then advances.
class OnboardingFormsController < ApplicationController
  def workspace_details
    run = RecordingStudioOnboarding::FlowRun.find(params.require(:run_id))
    name = params.dig(:workspace, :name).to_s.strip

    if name.blank?
      flash[:form_error] = "Workspace name can’t be blank."
      return redirect_to recording_studio_onboarding.run_path(run)
    end

    workspace = Workspace.create!(name: name)
    recording = RecordingStudio.root_recording_for(workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(
      recording: recording,
      actor: current_user
    )
    raise result.error if result.failure?

    RecordingStudioOnboarding.advance(run, from: params[:from], actor: current_user)
    redirect_to recording_studio_onboarding.run_path(run)
  end

  def presskit_images
    run = RecordingStudioOnboarding::FlowRun.find(params.require(:run_id))
    page = run.scope
    title = params.dig(:page, :title).to_s.strip

    if title.blank?
      flash[:form_error] = "Title can’t be blank."
      return redirect_to recording_studio_onboarding.run_path(run)
    end

    page.update!(title: title)
    RecordingStudioOnboarding.mark_viewed(run, actor: current_user)
    # complete_when may auto-advance when title includes "ready"
    redirect_to recording_studio_onboarding.run_path(run)
  end
end
