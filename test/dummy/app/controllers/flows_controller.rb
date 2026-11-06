# frozen_string_literal: true

require "recording_studio_onboarding/services/accessible_authorization"

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
    @pages = accessible_pages
    @active_account_setup = RecordingStudioOnboarding.active_run(:account_setup, actor: current_user)
    defer_before_onboarding!(return_path: main_app.flows_path) if @active_account_setup
  end

  def start
    subject = resolve_subject
    run = RecordingStudioOnboarding.start(
      params.require(:flow_key),
      actor: current_user,
      subject: subject
    )
    run_path = recording_studio_onboarding.run_path(run)
    return if defer_before_onboarding!(return_path: run_path)

    redirect_to run_path
  rescue RecordingStudioOnboarding::Unauthorized
    head :not_found
  end

  private

  def defer_before_onboarding!(return_path:)
    path = RecordingStudioOnboarding.before_onboarding_redirect_to(
      self,
      actor: current_user,
      return_path: return_path
    )
    return false if path.blank?

    redirect_to path
    true
  end

  def resolve_subject
    case params[:scope_type]
    when "Workspace"
      find_accessible_record!(Workspace, params.require(:scope_id))
    when "Page"
      find_accessible_record!(Page, params.require(:scope_id))
    end
  end

  def find_accessible_record!(klass, id)
    record = klass.find(id)
    return record if accessible_record?(record)

    raise ActiveRecord::RecordNotFound
  end

  def accessible_record?(record)
    RecordingStudioOnboarding::Services::AccessibleAuthorization.allowed?(
      actor: current_user,
      record: record
    )
  end

  def accessible_workspaces
    root_ids = RecordingStudioAccessible.root_recording_ids_for(actor: current_user)
    return [] if root_ids.blank?

    RecordingStudio::Recording.where(id: root_ids, recordable_type: "Workspace").filter_map(&:recordable)
  end

  def accessible_pages
    Page.order(:created_at).filter { |page| accessible_record?(page) }.first(20)
  end
end
