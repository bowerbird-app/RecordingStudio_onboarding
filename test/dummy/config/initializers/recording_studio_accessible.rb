# frozen_string_literal: true

RecordingStudioAccessible.configure do |config|
  config.access_actor_types = [ "User" ]

  # Accessible 0.45 authorizes mounted admin pages from this kept root.
  # The dummy's Studio Workspace root is that admin root.
  config.admin_root_resolver = lambda do |context: nil|
    workspace = Workspace.find_by(name: "Studio Workspace")
    next unless workspace

    RecordingStudio::Recording.kept.find_by(recordable: workspace)
  end
end
