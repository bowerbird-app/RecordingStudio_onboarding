# RecordingStudioOnboarding

Reusable onboarding and backend provisioning for Recording Studio applications.

This gem is independent of Recording Studio Terms & Conditions.

## What's Included

- **Provisioning registry** — named provisioners + `ProvisioningExecution`
- **Flow registry** — Ruby-configured sequences (`config.flow`)
- **`FlowRun` / `StepProgress`** — scoped persistence with row-lock transitions
- **Public API** — `start`, `active_run`, `advance`, `back`, `skip`, `dismiss`,
  `reset`, `restart`, `mark_viewed`, `preview` (no automatic redirect from `start`)
- **Card UI** — `RunComponent`, `CardShellComponent`, `ControlsComponent`,
  `ProgressComponent` (Flatpack Button / Progress / Stepper)
- **Engine routes** — `/onboarding/runs/:uuid` (+ advance/back/skip/dismiss)
- **Admin + analytics** — soft `RecordingStudioAdmin.register_*` section/screens
  for flows, card previews, runs, drop-off funnel, and provisioning
- **Dummy app** — provisioning, flow launcher, card layouts, host form steps, admin

## Quick Start

### Login Credentials

| Field    | Value             |
|----------|-------------------|
| Email    | admin@admin.com   |
| Password | Password          |

### Useful Routes

- `/` — demo home
- `/flows` — start flows; embedded `RunComponent` when an account_setup run is open
- `/onboarding/runs/:uuid` — full-screen card shell for the current step
- `/admin` — RS Admin root section (onboarding hub + screens)
- `/admin/root` — host admin landing with search
- `/onboarding/admin/previews/:flow/:step` — card preview (writes nothing)
- `/provisioning` — provisioning status
- `/users/sign_up` / `/users/sign_in` — RecordingStudio_users auth (not Devise chrome)

## Configuration

```ruby
RecordingStudioOnboarding.configure do |config|
  config.provision :new_registration, with: "Host::ProvisionRegistration"
  config.current_actor = ->(controller) { controller.current_user }

  # Optional override; default uses user identity or Accessible :view
  # config.authorize_run = ->(run, actor) { ... }

  # Admin card preview context (fake actor/subject; never persisted)
  config.preview_context = ->(flow_key:, step_key:) {
    { actor: current_user_for_preview, subject: workspace_for_preview }
  }

  config.flow :account_setup do
    scope :user
    progress :segments # or :bar
    dismissible true
    version 1
    after_complete "/"
    after_dismiss "/flows"
    step :welcome,
      component: "Host::Onboarding::WelcomeComponent",
      controls: %i[continue exit]
    step :details,
      component: "Host::Onboarding::DetailsComponent",
      controls: %i[back continue skip exit],
      skippable: true
  end
end
```

### Presentation modes

1. **Full screen** — redirect to `recording_studio_onboarding.run_path(run)`
2. **Embedded** — `render RecordingStudioOnboarding::RunComponent.new(run: run)`

### Form steps

Cards post to **host** controllers. On success the host calls
`RecordingStudioOnboarding.advance(run, from:, actor:)` then redirects back to
the run. Optional `complete_when:` auto-advances on render when true.

### Writing a card component

```ruby
class Host::Onboarding::WelcomeComponent < ViewComponent::Base
  def initialize(run:, step:)
    @run = run
    @step = step
  end

  def call
    # Own layout freely. Do not build navigation URLs —
    # the shell renders onboarding controls.
  end
end
```

## Admin integration

When `recording_studio_admin` is present, the engine registers (soft optional):

- Section `onboarding`
- Screens: `onboarding_flows`, `onboarding_previews`, `onboarding_runs`,
  `onboarding_funnel`, `onboarding_provisioning`
- Widgets: open runs, completion rate, failed provisions
- Resources: reset/restart run, retry provisioning

Enable the section on the host admin root:

```ruby
recording_studio_admin_sections do
  section :root
  section :onboarding
end
```

Drop-off analytics (§25) are SQL aggregates over `FlowRun` + `StepProgress`
(funnel reach, continuation %, completion/dismissal rates, median time-on-step).
No separate analytics store.

## Events

`*.recording_studio_onboarding`: `provision.*`, `flow.started`, `step.viewed`,
`step.completed`, `step.skipped`, `flow.completed`, `flow.dismissed`, `flow.reset`.

## RecordingStudio_users integration

Requires **RecordingStudio_users >= 0.15.0**.

Subscribes to `registration.completed.recording_studio_user` for every
successful sign-up method (`:password`, `:oauth`, `:otp`). Provisioning is
idempotent per actor, so duplicate events do not double-provision.

The older OTP-only event (`otp.registration_completed.recording_studio_user`)
is not subscribed; OTP is covered by the unified event.

The dummy mounts RS Users auth (`recording_studio_user_auth_for :users` plus
`RecordingStudioUser::Engine`) so `/users/sign_up` is the real users flow.
Password and OAuth sign-up emit the unified event; OTP registration is off in
the dummy until Notifications is installed.

## Architecture notes

- No dependency on RS Terms & Conditions
- Flatpack ViewComponents only; no React or Vue
- Dummy GitHub tag pins: RecordingStudio `v4.2.2`, Accessible `v0.11.1`,
  RecordingStudio_users `v0.15.0`, Root Switchable `v0.5.1`, Flatpack `v0.1.196`,
  Admin `v2.0.5`

## Development

```bash
bundle exec rake test
bundle exec rake test:all
```
