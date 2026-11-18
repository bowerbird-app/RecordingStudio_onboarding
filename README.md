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
  `reset`, `restart`, `mark_viewed`, `preview` (no automatic redirect from `start`).
  Workspace/subject `start` and `provision` need Accessible `:view` or they raise
  `Unauthorized`. `active_run` returns `nil` in that case.
- **Before-onboarding gates** — `config.before_onboarding` callables; RS Terms
  auto-registers when present
- **Card UI** — `RunComponent`, `CardShellComponent`, permanent chrome
  (`ChromeComponent` Back / Skip text links), line `ProgressComponent`,
  bottom `ControlsComponent` with a right-aligned Continue or Skip button, default
  `PageComponent` (splash / top-card / plain), shared `PageFrameComponent`
- **Engine routes** — `/onboarding/runs/:uuid` (+ advance/back/skip/dismiss)
- **Admin + analytics** — soft `RecordingStudioAdmin.register_*` section/screens
  for flows, card previews, runs, drop-off funnel, and provisioning
- **Dummy app** — provisioning, flow launcher, layout gallery
  (`/demos/onboarding`), host form steps, and admin. Terms Agree-before-onboarding
  waits on a 6.x Terms tag.

## Quick Start

### Login Credentials

| Field    | Value             |
|----------|-------------------|
| Email    | admin@admin.com   |
| Password | Password123!      |

### Useful Routes

- `/` — demo home
- `/flows` — start flows; embedded `RunComponent` when an account_setup run is open
- `/demos/onboarding` — layout gallery (splash, top-card, plain, button positions)
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
  # Optional. nil uses RecordingStudio.configuration.layout, then
  # recording_studio/default_layout. false skips the layout.
  # config.layout = "application"

  # Optional extra deny; default is user identity or Accessible :view
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
    progress :bar
    dismissible true
    version 1
    after_complete "/"
    after_dismiss "/flows"
    step :welcome,
      component: "Host::Onboarding::WelcomeComponent",
      controls: %i[continue],
      skippable: false
    step :details,
      component: "Host::Onboarding::DetailsComponent",
      controls: %i[continue],
      skippable: true,
      footer_action: :skip
  end
end
```

### Page chrome (permanent)

Full-screen and embedded shells always use:

- **Back** — plain text link with a Heroicons chevron-left icon, top-left
  (hidden on the first step)
- **`Skip`** — plain text link, top-right (hidden when `skippable: false`, and when the footer button is Skip)
- **Line progress** — Flatpack Progress bar; step 1 already shows color
- **No Exit** — removed from the UI (call `dismiss` in host code if needed)

### Default page element (`PageComponent`)

Subclass or instantiate `RecordingStudioOnboarding::PageComponent` with:

| Field | Meaning |
|--------|---------|
| `splash_image_url` | Full-bleed image; title + content overlay with a dark gradient tint |
| `image_url` | Top card image with border-radius on all corners; title + content below |
| `title` | Page title |
| `content` | HTML body (sanitized) |

If both image fields are set, **splash wins**.

### Flow and step options

| Option | Where | Meaning |
|--------|--------|---------|
| `scope` | flow | `:user`, `:workspace`, or `:subject` — how the run is keyed |
| `progress` | flow | `:bar` only (line progress; numbered segments removed) |
| `dismissible` | flow | When true, programmatic `dismiss` marks the run dismissed |
| `version` | flow | Integer definition version; open runs reconcile when it changes |
| `after_complete` | flow | Path, URL, or callable → destination after completion |
| `after_dismiss` | flow | Path, URL, or callable → destination after dismiss |
| `step :key` | flow | Ordered step; key is stable in `StepProgress` |
| `component` | step | ViewComponent class name string (required) |
| `controls` | step | Bottom actions — typically `%i[continue]` (default). `:exit` ignored. Back and the top Skip link are chrome. |
| `button_positions` | step | Still accepts `:left`, `:right`, or `:full`. The footer button always renders as an auto-width button on the right. |
| `show_progress` | step | When false, step is omitted from the progress count (default true) |
| `skippable` | step | When false, the top Skip link is hidden and skip is rejected (default true) |
| `footer_action` | step | `:continue` (default) or `:skip`. Picks the bottom button label and where it posts. |
| `complete_when` | step | Optional callable `(run) → truthy` to auto-advance on render |

`footer_action: :continue` posts to advance and records the step completed.
`:skip` posts to the existing skip action and records the step skipped.
`:skip` requires `skippable` (the default). `skippable: false` with
`footer_action: :skip` raises when the flow is defined. The bottom button
still needs `:continue` in `controls` (the default). When that button skips,
the top Skip link is hidden so Skip shows once.

**Step count / progress:** `FlowDefinition#visible_steps` keeps steps with
`show_progress: true`. `ProgressComponent` fills the bar to the 1-based current
visible step. Steps with `show_progress: false` still run; they do not advance
the visible index.

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

Requires **RecordingStudio_users >= 0.30.0**, **< 1.0**.

Subscribes to `registration.completed.recording_studio_user` for every
successful sign-up method (`:password`, `:oauth`, `:otp`). Provisioning is
idempotent per actor, so duplicate events do not double-provision.

The older OTP-only event (`otp.registration_completed.recording_studio_user`)
is not subscribed; OTP is covered by the unified event.

The dummy mounts RS Users auth (`recording_studio_user_auth_for :users` plus
`RecordingStudioUser::Engine`) so `/users/sign_up` is the real users flow.
Password and OAuth sign-up emit the unified event. OTP registration stays off
in the dummy (`otp_enabled = false`), so OTP-only paths return 404. Users 0.32
still draws the password confirmation code routes (`/users/sign_up/verify`
and resend) while password registration is on. `password_registration_confirmation`
is removed.

## Architecture notes

- No gemspec dependency on RS Terms & Conditions (soft optional gate)
- Flatpack ViewComponents only; no React or Vue
- Dummy and root GitHub tag pins match the Gemfiles: RecordingStudio `v7.3.0`,
  Accessible `v0.45.1`, Admin `v2.18.0`, API `v1.2.1`, Attachable `v0.31.0`,
  Cache `v0.7.0`, Icons `v0.4.0`, Logs `v0.8.0`, RecordingStudio_users `v0.32.0`,
  Metrics `v0.9.0`, Moveable `v6.0.0`, Trashable `v1.0.1`, Root Switchable
  `v0.16.0`, Flatpack `v0.1.377`.
  Dummy omits Terms and Publishable until Terms ships a core 7 tag.
  Gemspec: `recording_studio` `>= 7.0`, `< 8.0`, `recording_studio_user`
  `>= 0.30.0`, `< 1.0`. Create roots with `RecordingStudio.create_root_recording!`.
  `root_recording_for` only finds an existing root.
- CI also runs against `gemfiles/without_terms.gemfile`. Terms-gated dummy
  behavior is tested once a 6.x Terms tag exists.

## Development

Tests replace configuration with `RecordingStudioOnboarding.reset_for_tests!`.
Dummy integration tests that sign in call `accept_live_terms_for_tests!(actor)`
when they should pass the Terms gate. Handler failures from `provision` raise
`RecordingStudioOnboarding::ProvisionFailed` after the execution is marked failed.

```bash
bundle exec rake test
bundle exec rake test:all

# Without RS Terms (real absence — gem never required):
DUMMY_GEMFILE=gemfiles/without_terms.gemfile bundle exec rake test:all
```
