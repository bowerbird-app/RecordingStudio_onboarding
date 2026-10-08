# RecordingStudioOnboarding

Reusable onboarding and backend provisioning for Recording Studio applications.

This gem is independent of Recording Studio Terms & Conditions.

## PR 3 scope

Card shell, Flatpack controls/progress, `RunComponent`, engine run routes,
presentation modes (full-screen + embedded), host form-step contract,
authorisation via RecordingStudioAccessible, and exit destinations.

## What's Included

- **Provisioning registry** — named provisioners + `ProvisioningExecution`
- **Flow registry** — Ruby-configured sequences (`config.flow`)
- **`FlowRun` / `StepProgress`** — scoped persistence with row-lock transitions
- **Public API** — `start`, `active_run`, `advance`, `back`, `skip`, `dismiss`,
  `reset`, `mark_viewed` (no automatic redirect or render from `start`)
- **Card UI** — `RunComponent`, `CardShellComponent`, `ControlsComponent`,
  `ProgressComponent` (Flatpack Button / Progress / Stepper)
- **Engine routes** — `/onboarding/runs/:uuid` (+ advance/back/skip/dismiss)
- **Dummy app** — provisioning, flow launcher, card layouts, host form steps

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
- `/provisioning` — provisioning status
- `/users/sign_up` / `/users/sign_in`

## Configuration

```ruby
RecordingStudioOnboarding.configure do |config|
  config.provision :new_registration, with: "Host::ProvisionRegistration"
  config.current_actor = ->(controller) { controller.current_user }

  # Optional override; default uses user identity or Accessible :view
  # config.authorize_run = ->(run, actor) { ... }

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
    # the shell renders onboarding_controls(run).
  end
end
```

## Events

`*.recording_studio_onboarding`: `provision.*`, `flow.started`, `step.viewed`,
`step.completed`, `step.skipped`, `flow.completed`, `flow.dismissed`, `flow.reset`.

## RecordingStudio_users integration

OTP: `otp.registration_completed.recording_studio_user`. Password/OmniAuth hooks
are not yet available — hosts call `provision` explicitly for those paths.

## Architecture notes

- No dependency on RS Terms & Conditions
- Flatpack ViewComponents only; no React or Vue
- Dummy GitHub tag pins: RecordingStudio `v4.2.2`, Accessible `v0.10.1`,
  Root Switchable `v0.5.1`, Flatpack `v0.1.196`

## Development

```bash
bundle exec rake test
bundle exec rake test:all
```
