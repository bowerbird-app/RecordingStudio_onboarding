# RecordingStudioOnboarding

Reusable onboarding and backend provisioning for Recording Studio applications.

This gem is independent of Recording Studio Terms & Conditions.

## PR 2 scope

This release covers named flow registry, scopes, `FlowRun` / `StepProgress`
persistence, the public flow API, concurrency, definition versioning, and
instrumentation events. Card UI, engine routes, and admin analytics arrive in
later PRs.

## What's Included

- **Provisioning registry** — host apps and other gems register named provisioners
- **`ProvisioningExecution`** — UUID-backed idempotent execution tracking
- **Flow registry** — Ruby-configured named sequences (`config.flow`)
- **`FlowRun` / `StepProgress`** — scoped persistence with row-lock transitions
- **Public API** — `start`, `active_run`, `advance`, `back`, `skip`, `dismiss`,
  `reset`, `mark_viewed` (no automatic redirect or render)
- **Recording Studio** 4.x + Accessible wiring in the dummy host app
- **Dummy app** demonstrating registration provisioning plus flow/run demo pages

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

- `/` — demo home
- `/users/sign_up` — Devise registration (triggers `:new_registration`)
- `/users/sign_in` — Devise sign-in (does not re-provision)
- `/provisioning` — execution status and owned workspaces
- `/flows` — registered flows and recent runs (PR 2 demo)
- `/flow_runs/:id` — run/step progress and transition controls (PR 2 demo)
- `/onboarding` — mounted engine (card routes arrive in PR 3)

## Configuration

```ruby
# config/initializers/recording_studio_onboarding.rb
RecordingStudioOnboarding.configure do |config|
  config.provision :new_registration,
    with: "Dummy::ProvisionRegistration"

  config.flow :account_setup do
    scope :user
    progress :segments
    dismissible true
    version 1
    step :welcome, component: "Host::Onboarding::WelcomeComponent"
    step :workspace_details, component: "Host::Onboarding::WorkspaceDetailsComponent"
    step :complete,
      component: "Host::Onboarding::CompleteComponent",
      show_progress: false
  end
end
```

### Public API

```ruby
RecordingStudioOnboarding.provision(:new_registration, actor: user, subject: user)

run = RecordingStudioOnboarding.start(:account_setup, actor: current_user)
RecordingStudioOnboarding.active_run(:account_setup, actor: current_user)
RecordingStudioOnboarding.advance(run, from: :welcome, actor: current_user)
RecordingStudioOnboarding.back(run, from: :workspace_details, actor: current_user)
RecordingStudioOnboarding.skip(run, from: :workspace_details, actor: current_user)
RecordingStudioOnboarding.dismiss(run, actor: current_user)
RecordingStudioOnboarding.reset(run, actor: current_user)
RecordingStudioOnboarding.mark_viewed(run, actor: current_user)
```

`start` never redirects or renders UI — the host decides presentation.

Scopes: `:user` (once per actor), `:workspace` (once per root workspace),
`:subject` (once per record). Workspace/subject uniqueness excludes the initiating
actor; the actor is stored separately on the run.

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

## Events

`ActiveSupport::Notifications` under `*.recording_studio_onboarding`:

- `provision.started`, `provision.completed`, `provision.failed`
- `flow.started`, `step.viewed`, `step.completed`, `step.skipped`,
  `flow.completed`, `flow.dismissed`, `flow.reset`

Payloads include run/execution UUID, flow or provisioner key, step key, scope
type/id, and actor id — no sensitive data.

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
- Applications explicitly trigger provisioning and flows
- No dependency on RS Terms & Conditions
- Flatpack ViewComponents only for UI (card shell in PR 3); no React or Vue
- Concurrency: open-run unique partial index + `with_lock` transitions with `from:`
  stale no-op; definition versioning reconciles open runs without reopening completed ones
- Dummy GitHub tag pins: RecordingStudio `v4.2.2`, Accessible `v0.10.1`,
  Root Switchable `v0.5.1`, Flatpack `v0.1.196`

## Development

```bash
bundle exec rake test
bundle exec rake test:all
```
