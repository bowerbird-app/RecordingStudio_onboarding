# Migration Notes

## Current Requirements

- Ruby 3.3 or newer
- Rails 8.1 or newer
- Recording Studio 4.x (`~> 4.2` in the gemspec; dummy GitHub tag `v4.2.2`)
- RecordingStudio_users `>= 0.18.0` (dummy/root GitHub tag `v0.18.0`) for the
  registration-completed provisioning subscriber; dummy mounts users auth
- RecordingStudio_metrics `v0.2.0` (Users 0.18 dependency; GitHub tag pin)
- Accessible dummy tag `v0.11.1`, Attachable `v0.7.1`, Admin `v2.0.5`,
  Root Switchable `v0.5.1`
- FlatPack dummy tag `v0.1.196`
- Public RubyGems and GitHub access for dependency installation

## Verification

Install both bundles and run the complete gem and dummy app test path:

```bash
bundle install
BUNDLE_GEMFILE=test/dummy/Gemfile bundle install
bundle exec rake test:all
```

Run the dummy app from its directory for browser verification:

```bash
cd test/dummy
bin/dev
```

Use the [FlatPack repository](https://github.com/bowerbird-app/flatpack) and the live FlatPack demo linked from the top-level README for current component documentation.
