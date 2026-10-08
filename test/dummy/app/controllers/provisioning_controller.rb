# frozen_string_literal: true

class ProvisioningController < ApplicationController
  def show
    @executions = RecordingStudioOnboarding::ProvisioningExecution
                  .where(actor: current_user)
                  .order(created_at: :desc)
    @workspaces = accessible_workspaces
  end

  private

  def accessible_workspaces
    root_ids = RecordingStudioAccessible.root_recording_ids_for(actor: current_user)
    return [] if root_ids.blank?

    RecordingStudio::Recording.where(id: root_ids, recordable_type: "Workspace").filter_map(&:recordable)
  end
end

