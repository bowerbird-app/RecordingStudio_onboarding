# frozen_string_literal: true

require "test_helper"

class UsersDirectoryProfileWriteGapTest < ActionDispatch::IntegrationTest
  test "Users Directory.create_user! writes a Profile under dummy authorize_write without a host prepend" do
    initializer = Rails.root.join("config/initializers/recording_studio_user_directory_actor.rb")
    refute File.exist?(initializer), "do not restore a Directory.create_user! prepend shim"
    refute_includes File.read(Rails.root.join("app/models/user.rb")), "recording_studio_user_directory_create"

    skip "Users gap: Directory.create_user! and record_profile! have no API for a first " \
         "Profile write when host authorize_write allows AccessCreationContext only for " \
         "RecordingStudio::Access and Accessible :edit otherwise. Users v0.28.1 writes the " \
         "Profile before bootstrap_owner_access! and OmniAuth omits actor:."
  end
end
