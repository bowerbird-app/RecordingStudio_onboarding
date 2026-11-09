# frozen_string_literal: true

module OwnedRootHelper
  def owned_root_for(workspace, actor: owning_test_actor)
    root_recording = RecordingStudio.root_recording_for(workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(
      recording: root_recording,
      actor: actor
    )
    raise result.error if result.failure?

    root_recording
  end

  def owning_test_actor
    return @actor if defined?(@actor) && @actor
    return @user if defined?(@user) && @user

    raise ArgumentError, "owned_root_for needs an actor"
  end
end
