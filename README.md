# RecordingStudioOnboarding

Reusable onboarding and backend provisioning for Recording Studio applications.

This gem is independent of Recording Studio Terms & Conditions.

## PR 1 scope

This release covers gem identity, the provisioning registry, `ProvisioningExecution`
tracking, and host-triggered workspace provisioning. Interactive onboarding flows,
cards, and admin analytics arrive in later PRs.

## What's Included

- **Provisioning registry** — host apps and other gems register named provisioners
- **`ProvisioningExecution`** — UUID-backed idempotent execution tracking
- **Recording Studio** 4.x + Accessible wiring in the dummy host app
- **Dummy app** demonstrating registration-triggered workspace provisioning

## Quick Start

### Cursor Cloud Agent

`.cursor/install.sh` provisions Ruby, PostgreSQL, gems, the seeded dummy database,
and compiled CSS. Open port 3000 and sign in at `/users/sign_in`.

### Login Credentials

| Field    | Value             |
|----------|-------------------|
| Email    | admin@admin.com   |
| Password | Password          |

### Useful Routes

- `/` — provisioning demo home
- `/users/sign_up` — Devise registration (triggers `:new_registration`)
- `/users/sign_in` — Devise sign-in (does not re-provision)
- `/provisioning` — execution status and owned workspaces
- `/onboarding` — mounted engine (flow routes arrive in PR 3)

## Configuration

```ruby
# config/initializers/recording_studio_onboarding.rb
RecordingStudioOnboarding.configure do |config|
  config.provision :new_registration,
    with: "Dummy::ProvisionRegistration"
end
```

```ruby
RecordingStudioOnboarding.provision(
  :new_registration,
  actor: user,
  subject: user
)
```

Provisioners are service objects that respond to `.call(actor:, subject:, root:, context:)`.
Workspace creation stays host-configurable — the gem does not hardcode it.

### Installation

```ruby
# Gemfile
gem "recording_studio_onboarding", github: "bowerbird-app/RecordingStudio_onboarding"
```

```bash
bin/rails generate recording_studio_onboarding:install
bin/rails generate recording_studio_onboarding:migrations
bin/rails db:migrate
```

Default engine mount path is `/onboarding`.

## RecordingStudio_users integration

Where a real extension point exists, the gem subscribes to:

`otp.registration_completed.recording_studio_user`

Password registration and OmniAuth new-account creation do **not** currently expose
a public hook in RecordingStudio_users. Hosts must call
`RecordingStudioOnboarding.provision` explicitly after those paths (as the dummy
Devise registrations controller does) until Users adds a registration-completed
notification.

## Architecture notes

- Provisioning and interactive onboarding are independent
- Applications explicitly trigger provisioning
- No dependency on RS Terms & Conditions
- Flatpack ViewComponents only for UI (later PRs); no React or Vue
- Dummy GitHub tag pins: RecordingStudio `v4.2.2`, Accessible `v0.10.1`,
  Root Switchable `v0.5.1`, Flatpack `v0.1.196`

## Development

```bash
bundle exec rake test
bundle exec rake test:all
```
