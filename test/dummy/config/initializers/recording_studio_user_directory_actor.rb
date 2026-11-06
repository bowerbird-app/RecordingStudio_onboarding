# frozen_string_literal: true

# Directory.create_user! writes a Profile through record! before Warden has a
# session. Mark the thread so User#after_create can set Current.actor.
module Dummy
  module DirectoryCreateActor
    def create_user!(email:, password:, password_confirmation: nil, actor: nil, **attributes)
      previous = Thread.current[:recording_studio_user_directory_create]
      Thread.current[:recording_studio_user_directory_create] = true
      super
    ensure
      Thread.current[:recording_studio_user_directory_create] = previous
    end
  end
end

Rails.application.config.to_prepare do
  next unless defined?(RecordingStudioUser::Directory)

  RecordingStudioUser::Directory.singleton_class.prepend(Dummy::DirectoryCreateActor)
end
