# frozen_string_literal: true

# Dummy demo surface for PR 2 — lists registered flows and open/closed runs.
# Card UI arrives in PR 3; this page only shows state and transition controls.
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
  end

  def start
    subject = resolve_subject
    run = RecordingStudioOnboarding.start(
      params.require(:flow_key),
      actor: current_user,
      subject: subject
    )
    RecordingStudioOnboarding.mark_viewed(run, actor: current_user)
    redirect_to flow_run_path(run), notice: "Started #{run.flow_key}"
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
