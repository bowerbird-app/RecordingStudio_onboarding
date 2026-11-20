# frozen_string_literal: true

require "test_helper"

class UsersDirectoryProfileWriteGapTest < ActionDispatch::IntegrationTest
  test "Users Directory.create_user! writes a Profile under dummy authorize_write without a host prepend" do
    initializer = Rails.root.join("config/initializers/recording_studio_user_directory_actor.rb")
    refute File.exist?(initializer), "do not restore a Directory.create_user! prepend shim"
    refute_includes File.read(Rails.root.join("app/models/user.rb")), "recording_studio_user_directory_create"

    email = "gap-user-#{SecureRandom.hex(4)}@example.com"
    user = RecordingStudioUser::Directory.create_user!(
      email: email,
      password: "Password123!",
      password_confirmation: "Password123!",
      first_name: "Gap",
      last_name: "User",
      confirm: true
    )

    profile = RecordingStudioUser::Directory.profile_for(user)
    assert profile, "expected create_user! to record a Profile"
    assert_equal user.id, profile.user_id
  end
end
