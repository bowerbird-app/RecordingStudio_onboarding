# frozen_string_literal: true

require "test_helper"
require "recording_studio_onboarding/services/failure_sanitizer"

class FailureSanitizerTest < Minitest::Test
  def test_scrubs_password_assignments
    error = StandardError.new("failed password=hunter2 token:abc123 api_key=sekrit")
    scrubbed = RecordingStudioOnboarding::Services::FailureSanitizer.call(error)

    assert_includes scrubbed, "StandardError:"
    assert_includes scrubbed, "password=[FILTERED]"
    assert_includes scrubbed, "token=[FILTERED]"
    assert_includes scrubbed, "api_key=[FILTERED]"
    refute_includes scrubbed, "hunter2"
    refute_includes scrubbed, "abc123"
    refute_includes scrubbed, "sekrit"
  end

  def test_preserves_non_sensitive_message
    error = RuntimeError.new("workspace already exists")
    scrubbed = RecordingStudioOnboarding::Services::FailureSanitizer.call(error)

    assert_equal "RuntimeError: workspace already exists", scrubbed
  end
end
