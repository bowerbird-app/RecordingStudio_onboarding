# RecordingStudioOnboarding

Reusable onboarding and backend provisioning for Recording Studio applications.

This gem is independent of Recording Studio Terms & Conditions. When that gem is
installed, onboarding auto-registers a soft gate so Agree runs before the
user-facing flow.

## What's Included

- **Provisioning registry** — named provisioners + `ProvisioningExecution`
- **Flow registry** — Ruby-configured sequences (`config.flow`)
- **`FlowRun` / `StepProgress`** — scoped persistence with row-lock transitions
- **Public API** — `start`, `active_run`, `advance`, `back`, `skip`, `dismiss`,
  `reset`, `restart`, `mark_viewed`, `preview` (no automatic redirect from `start`)
- **Before-onboarding gates** — `config.before_onboarding` callables; RS Terms
  auto-registers when present
- **Card UI** — `RunComponent`, `CardShellComponent`, `ControlsComponent`,
  `ProgressComponent` (Flatpack Button / Progress; segment trail with labels
  above the connector), shared `PageFrameComponent` width for admin / preview /
  full-screen steps
- **Engine routes** — `/onboarding/runs/:uuid` (+ advance/back/skip/dismiss)
- **Admin + analytics** — soft `RecordingStudioAdmin.register_*` section/screens
  for flows, card previews, runs, drop-off funnel, and provisioning
- **Dummy app** — provisioning, flow launcher, card layouts, host form steps,
  admin, optional RS Terms Agree-before-onboarding demo

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
- `/recording_studio_terms_and_conditions/acceptance` — RS Terms Agree (when installed)
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

  # Optional host gates before user-facing onboarding (see Terms gate below).
  # config.before_onboarding do |controller:, actor:, return_path:|
  #   nil # or a redirect path
  # end

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

### Flow and step options

| Option | Where | Meaning |
|--------|--------|---------|
| `scope` | flow | `:user`, `:workspace`, or `:subject` — how the run is keyed |
| `progress` | flow | `:segments` (numbered trail) or `:bar` (Flatpack Progress) |
| `dismissible` | flow | When true, Exit dismisses the run; when false, Exit leaves the screen open |
| `version` | flow | Integer definition version; open runs reconcile when it changes |
| `after_complete` | flow | Path, URL, or callable → destination after completion |
| `after_dismiss` | flow | Path, URL, or callable → destination after dismiss |
| `step :key` | flow | Ordered step; key is stable in `StepProgress` |
| `component` | step | ViewComponent class name string (required) |
| `controls` | step | Subset of `:back`, `:continue`, `:skip`, `:exit` (default `%i[back continue]`) |
| `show_progress` | step | When false, step is omitted from the progress count/trail (default true) |
| `skippable` | step | When false, Skip is rejected even if listed in controls (default true) |
| `complete_when` | step | Optional callable `(run) → truthy` to auto-advance on render |

**Step count / progress:** `FlowDefinition#visible_steps` keeps steps with
`show_progress: true`. `ProgressComponent` uses that list for segment markers and
the bar (`done of visible`). Steps with `show_progress: false` still run; they
do not advance the visible index.

### Presentation modes

1. **Full screen** — redirect to `recording_studio_onboarding.run_path(run)`
2. **Embedded** — `render RecordingStudioOnboarding::RunComponent.new(run: run)`

Both defer to `config.before_onboarding` gates before showing cards. Host start
actions should call `RecordingStudioOnboarding.before_onboarding_redirect_to`
(see dummy `FlowsController`) so redirect-to-run waits the same way.

### Before-onboarding gates (Terms first)

```ruby
# Signature for every gate:
#   call(controller:, actor:, return_path:) → redirect path or nil
# First non-nil path wins. Provisioning is never gated.

RecordingStudioOnboarding.before_onboarding_redirect_to(
  controller,
  actor: current_user,
  return_path: recording_studio_onboarding.run_path(run)
)
```

When `RecordingStudioTermsAndConditions` is defined, the engine auto-registers
`RecordingStudioOnboarding::Gates::TermsAndConditions`. That gate uses the Terms
public API only:

- `RecordingStudioTermsAndConditions.requires_acceptance?(actor, root)`
- `RecordingStudioTermsAndConditions::Gate.root_for_acceptance(controller)`
- `RecordingStudioTermsAndConditions::Gate.acceptance_path(controller)`

Return path uses Devise `store_location_for(:user, return_path)`. The Terms Agree
controller reads `stored_location_for(:user)` after accept. There is no
`return_to` query param on the Agree URL — do not invent one.

If Terms is not installed, or nothing is due, behavior matches earlier releases
(onboarding shows immediately). Soft optional: **no gemspec dependency** on
Terms or Publishable.

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

Requires **RecordingStudio_users >= 0.18.0**.

Subscribes to `registration.completed.recording_studio_user` for every
successful sign-up method (`:password`, `:oauth`, `:otp`). Provisioning is
idempotent per actor, so duplicate events do not double-provision.

The older OTP-only event (`otp.registration_completed.recording_studio_user`)
is not subscribed; OTP is covered by the unified event.

The dummy mounts RS Users auth (`recording_studio_user_auth_for :users` plus
`RecordingStudioUser::Engine`) so `/users/sign_up` is the real users flow.
Password and OAuth sign-up emit the unified event. OTP registration stays off
in the dummy (`otp_enabled = false`); with Users 0.18+, OTP paths are absent
and return 404 rather than error pages.

## Architecture notes

- No gemspec dependency on RS Terms & Conditions (soft optional gate)
- Flatpack ViewComponents only; no React or Vue
- Dummy GitHub tag pins: RecordingStudio `v4.2.2`, Accessible `v0.11.1`,
  RecordingStudio_users `v0.18.0`, Metrics `v0.2.0`, Root Switchable `v0.5.1`,
  Flatpack `v0.1.196`, Admin `v2.0.5`, Publishable `v0.4.2`,
  Terms & Conditions `v0.9.0`

## Development

```bash
bundle exec rake test
bundle exec rake test:all
```
