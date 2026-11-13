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
    assert_includes source, "load File.expand_path(\"admin.rb\""
  end

  def test_admin_support_files_reload_with_the_namespace
    source = File.read(File.expand_path("../lib/recording_studio_onboarding/admin.rb", __dir__))

    refute_includes source, "require_relative \"admin/"
    assert_includes source, "load File.expand_path(\"admin/support_loader.rb\", __dir__)"
    loader = File.read(File.expand_path("../lib/recording_studio_onboarding/admin/support_loader.rb", __dir__))
    assert_includes loader, "def self.load_support_files!"
    assert_includes loader, "const_defined?(:Registrar, false)"
    assert_includes loader, "registrar"
  end
end
