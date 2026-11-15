# frozen_string_literal: true

RecordingStudioAccessible.configure do |config|
  config.access_actor_types = [ "User" ]

  # Site-wide admin screens resolve only when this kept root matches the admin
  # access recording and the actor holds a role on it.
  config.admin_root_resolver = lambda do |context: nil|
    admin_root = AdminRoot.find_by(name: "Admin")
    next unless admin_root

    RecordingStudio::Recording.kept.find_by(recordable: admin_root)
  end
end
