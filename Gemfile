# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in recording_studio_onboarding.gemspec
gemspec

# recording_studio is not published to RubyGems; resolve the gemspec pin from GitHub.
gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "v6.5.0"

# recording_studio_user and its GitHub-only companions.
gem "flat_pack", github: "bowerbird-app/flatpack", tag: "v0.1.341"
gem "recording_studio_accessible", github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.24.2"
# Admin stays 2.8.2 (off the 2.5.1 host policy). 2.5.1 cannot resolve
# Recording Studio 6.x / FlatPack 0.1.341 / Trashable 0.12.
gem "recording_studio_admin", github: "bowerbird-app/RecordingStudio_admin", tag: "v2.8.2"
gem "recording_studio_attachable", github: "bowerbird-app/RecordingStudio_attachable", tag: "v0.22.1"
gem "recording_studio_cache", github: "bowerbird-app/RecordingStudio_cache", tag: "v0.6.3"
gem "recording_studio_logs", github: "bowerbird-app/RecordingStudio_logs", tag: "v0.7.4"
gem "recording_studio_metrics", github: "bowerbird-app/RecordingStudio_metrics", tag: "v0.7.3"
gem "recording_studio_trashable", github: "bowerbird-app/RecordingStudio_trashable", tag: "v0.12.3", require: false
gem "recording_studio_user", github: "bowerbird-app/RecordingStudio_users", tag: "v0.27.1"

gem "devise"
gem "puma"
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
