# frozen_string_literal: true

module Dummy
  # Host-app provisioner for :new_registration.
  # Creates a Workspace root via Recording Studio and grants the actor owner access
  # via RecordingStudioAccessible.bootstrap_owner_access!.
  class ProvisionRegistration
    def self.call(actor:, subject: nil, root: nil, context: {})
      new(actor: actor, subject: subject, root: root, context: context).call
    end

    def initialize(actor:, subject: nil, root: nil, context: {})
      @actor = actor
      @subject = subject
      @root = root
      @context = context || {}
    end

    def call
      existing = existing_owned_workspace
      return existing if existing

      workspace = Workspace.create!(name: workspace_name)
      recording = RecordingStudio.root_recording_for(workspace)

      result = RecordingStudioAccessible.bootstrap_owner_access!(
        recording: recording,
        actor: @actor
      )
      raise result.error if result.failure?

      workspace
    end

    private

    def workspace_name
      label = @actor.respond_to?(:email) && @actor.email.present? ? @actor.email : "User #{@actor.id}"
      "#{label}'s Workspace"
    end

    def existing_owned_workspace
      root_ids = RecordingStudioAccessible.root_recording_ids_for(actor: @actor, minimum_role: :admin)
      return if root_ids.blank?

      RecordingStudio::Recording.where(id: root_ids, recordable_type: "Workspace").filter_map do |recording|
        recording.recordable
      end.first
    end
  end
end
