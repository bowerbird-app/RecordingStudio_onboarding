# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in recording_studio_onboarding.gemspec
gemspec

# Recording Studio family. GitHub release tags only (no branch: or raw ref:).
gem "flat_pack", github: "bowerbird-app/flatpack", tag: "v0.1.377"
gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "v7.3.0"
gem "recording_studio_accessible", github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.45.1"
gem "recording_studio_admin", github: "bowerbird-app/RecordingStudio_admin", tag: "v2.18.0"
# Attachable 0.31 depends on API 1.x; API depends on Moveable and Icons.
# require: false keeps those engines from booting in this gem's test process.
gem "recording_studio_api", github: "bowerbird-app/RecordingStudio_api", tag: "v1.2.1", require: false
gem "recording_studio_attachable", github: "bowerbird-app/RecordingStudio_attachable", tag: "v0.31.0"
gem "recording_studio_cache", github: "bowerbird-app/RecordingStudio_cache", tag: "v0.7.0"
gem "recording_studio_icons", github: "bowerbird-app/RecordingStudio_icons", tag: "v0.4.0", require: false
gem "recording_studio_logs", github: "bowerbird-app/RecordingStudio_logs", tag: "v0.8.0"
gem "recording_studio_metrics", github: "bowerbird-app/RecordingStudio_metrics", tag: "v0.9.0"
gem "recording_studio_moveable", github: "bowerbird-app/RecordingStudio_moveable", tag: "v6.0.0", require: false
gem "recording_studio_trashable", github: "bowerbird-app/RecordingStudio_trashable", tag: "v1.0.1", require: false
gem "recording_studio_user", github: "bowerbird-app/RecordingStudio_users", tag: "v0.32.0"

gem "devise"
gem "puma", "8.1.1"
gem "sprockets-rails"

group :development, :test do
  gem "debug"
  gem "minitest-mock"
  gem "simplecov", require: false
end

group :development do
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
end
