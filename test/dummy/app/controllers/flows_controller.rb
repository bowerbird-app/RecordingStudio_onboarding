# frozen_string_literal: true

# Dummy launcher for registered flows. Starts a run then redirects to engine routes.
class FlowsController < ApplicationController
  def index
    @flows = RecordingStudioOnboarding.configuration.flows.values
    @runs = RecordingStudioOnboarding::FlowRun
            .where(initiating_actor: current_user)
            .or(RecordingStudioOnboarding::FlowRun.where(scope: current_user))
            .order(created_at: :desc)
            .limit(50)
    @workspaces = accessible_workspaces
    @pages = Page.order(:created_at).limit(20)
    @active_account_setup = RecordingStudioOnboarding.active_run(:account_setup, actor: current_user)
  end

  def start
    subject = resolve_subject
    run = RecordingStudioOnboarding.start(
      params.require(:flow_key),
      actor: current_user,
      subject: subject
    )
    redirect_to recording_studio_onboarding.run_path(run)
  end

  private

  def resolve_subject
    case params[:scope_type]
    when "Workspace"
      Workspace.find(params.require(:scope_id))
    when "Page"
      Page.find(params.require(:scope_id))
    end
  end

  def accessible_workspaces
    root_ids = RecordingStudioAccessible.root_recording_ids_for(actor: current_user)
    return [] if root_ids.blank?

    RecordingStudio::Recording.where(id: root_ids, recordable_type: "Workspace").filter_map(&:recordable)
  end
end
