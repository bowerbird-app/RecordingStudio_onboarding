# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in recording_studio_onboarding.gemspec
gemspec

# Recording Studio family. GitHub release tags only (no branch: or raw ref:).
gem "flat_pack", github: "bowerbird-app/flatpack", tag: "v0.1.376"
gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "v7.0.0"
gem "recording_studio_accessible", github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.44.0"
gem "recording_studio_admin", github: "bowerbird-app/RecordingStudio_admin", tag: "v2.16.0"
# Attachable 0.28 depends on API; API depends on Moveable and Icons.
# require: false keeps those engines from booting in this gem's test process.
gem "recording_studio_api", github: "bowerbird-app/RecordingStudio_api", tag: "v0.24.0", require: false
gem "recording_studio_attachable", github: "bowerbird-app/RecordingStudio_attachable", tag: "v0.28.0"
gem "recording_studio_cache", github: "bowerbird-app/RecordingStudio_cache", tag: "v0.6.3"
gem "recording_studio_icons", github: "bowerbird-app/RecordingStudio_icons", tag: "v0.2.1", require: false
gem "recording_studio_logs", github: "bowerbird-app/RecordingStudio_logs", tag: "v0.8.0"
gem "recording_studio_metrics", github: "bowerbird-app/RecordingStudio_metrics", tag: "v0.9.0"
gem "recording_studio_moveable", github: "bowerbird-app/RecordingStudio_moveable", tag: "v5.0.0", require: false
gem "recording_studio_trashable", github: "bowerbird-app/RecordingStudio_trashable", tag: "v0.17.0", require: false
gem "recording_studio_user", github: "bowerbird-app/RecordingStudio_users", tag: "v0.30.0"

gem "devise"
gem "puma", "8.1.0"
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
