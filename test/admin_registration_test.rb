# frozen_string_literal: true

require "test_helper"

class AdminRegistrationTest < Minitest::Test
  def test_admin_module_file_exists
    path = File.expand_path("../lib/recording_studio_onboarding/admin.rb", __dir__)
    assert File.file?(path)
  end

  def test_register_is_noop_without_recording_studio_admin
    # Soft optional: engine gates on defined?(RecordingStudioAdmin).
    source = File.read(File.expand_path("../lib/recording_studio_onboarding/engine.rb", __dir__))
    assert_includes source, "defined?(RecordingStudioAdmin)"
    assert_includes source, "RecordingStudioOnboarding::Admin.register!"
  end
end
