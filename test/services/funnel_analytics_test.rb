# frozen_string_literal: true

require "test_helper"

# Funnel analytics requires ActiveRecord + DB. Covered in
# test/dummy/test/integration/admin_onboarding_test.rb and
# test/dummy/test/services/funnel_analytics_test.rb.
class FunnelAnalyticsLoadTest < Minitest::Test
  def test_funnel_analytics_file_loads
    path = File.expand_path("../../lib/recording_studio_onboarding/services/funnel_analytics.rb", __dir__)
    assert File.file?(path)
  end
end
