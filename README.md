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
  `reset`, `restart`, `mark_viewed`, `preview`, `setup_status` (no automatic
  redirect from `start`). Workspace/subject `start` and `provision` need
  Accessible `:view` or they raise `Unauthorized`. `active_run` returns `nil`
  in that case.
- **Setup checklists** — host-registered items with a saved complete flag,
  a live Your setup page, an optional Dashboard widget, and a background
  recheck. Separate from flows.
- **Before-onboarding gates** — `config.before_onboarding` callables; RS Terms
  auto-registers when present
- **Card UI** — `RunComponent`, `CardShellComponent`, permanent chrome
  (`ChromeComponent` Back / Skip text links), line `ProgressComponent`,
  bottom `ControlsComponent` with left/right/full Continue, default
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
- `/onboarding/setup/:checklist` — Your setup (live checklist)
- `/dashboard` — dummy studio dashboard with the optional setup widget
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
      skippable: true
  end
end
```

### Page chrome (permanent)

Full-screen and embedded shells always use:

- **Back** — plain text link with a Heroicons chevron-left icon, top-left
  (hidden on the first step)
- **`Skip`** — plain text link, top-right (hidden when `skippable: false`)
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
| `controls` | step | Bottom actions — typically `%i[continue]` (default). `:exit` ignored. Back/Skip are chrome. |
| `button_positions` | step | Still accepts `:left`, `:right`, or `:full`. Continue always renders as an auto-width button on the right. |
| `show_progress` | step | When false, step is omitted from the progress count (default true) |
| `skippable` | step | When false, Skip chrome is hidden and skip is rejected (default true) |
| `complete_when` | step | Optional callable `(run) → truthy` to auto-advance on render |

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

## Setup checklists

A checklist answers whether an account is set up, and what to do next. It stays
useful after onboarding. It does not depend on which flow steps ran. Registering
one does not gate provisioning.

```ruby
config.setup_recheck_interval = 5.minutes # default

config.checklist :studio do
  scope :user # :user, :workspace, or :subject
  applies_to ->(actor, _scope) { actor.staff? } # optional, host-defined
  title "Finish your studio" # optional, default "Your setup"
  subtitle remaining: "Here's what's left.", # optional, see below
    complete: "The studio is ready.",
    not_applicable: "This list isn't for you."
  item :profile,
    check: ->(actor, _scope) { actor.email.present? },
    next_step: "Confirm the email on your account",
    link: -> { main_app.new_press_kit_path }, # path, absolute URL, or a callable
    icon: :queue_list, # optional FlatPack icon name
    applies_to: ->(actor, _scope) { actor.staff? } # optional
end
```

`link` is the page where the person takes that action (create a press kit, confirm
an email). Pass a path (`"/press_kits/new"`), an absolute `http(s)` URL, or a
callable. A zero-argument callable runs in the host's URL context, so
`-> { main_app.new_press_kit_path }` works from an initializer. A callable that
takes arguments receives the actor and the scope target. The setup page renders
that path on the row. Cards and step components still do not build navigation
URLs.

`icon` is a FlatPack icon name. It defaults to `:queue_list`.

`title` is the page heading and the browser tab. It defaults to "Your setup".
`subtitle` is the line under that heading. Omit it and the page uses "What to do
next." while items remain, "You're all set." when they are done, and "Nothing
here applies to you." when the checklist does not apply. Set one string to use
it for every state. Set `remaining:`, `complete:`, or `not_applicable:` for the
states you want to change. A callable receives the status and returns the line.
A block with no arguments returns one line for every state.
Pass text you have already translated. This gem does not look up translation
keys.

The setup page lists only what is still left. Each row is the icon, the
next-step line, and a link across the whole row. When nothing remains, the page
says you're done. From the medium breakpoint up, the heading, that list, and
the done line sit in the first column of a two-column grid. The second column
is empty. Narrower screens use one full-width column. `setup_status` still
returns both the done and remaining lists.

`check` and `applies_to` receive the actor and the scope target. A check that
returns a truthy value means the item is done. An item whose `applies_to`
returns false is hidden and left out of completeness. A check that raises counts
as not done, is logged, and does not raise into the page, the caller, or the
recheck job. A raising `applies_to` is logged and treated as applying, so a
failure cannot mark the list complete by hiding the item.

```ruby
status = RecordingStudioOnboarding.setup_status(:studio, actor: current_user)
status.complete?
status.next_item&.next_step
status.next_item&.link
status.done
status.remaining
```

The first call for an actor and scope computes and saves. Later calls return
that saved answer, then enqueue `RecheckSetupJob` when the saved check is older
than `setup_recheck_interval`. The job corrects the row if the account went
backwards. Your setup always computes live and updates the saved row. Workspace
and subject checklists take `subject_type` and `subject_id` on that page.
Authorization matches runs. The signed-in person sees a `:user` checklist.
Workspace and subject checklists need Accessible `:view`.

When Warden is loaded, a successful sign-in enqueues the same recheck. If
Warden is absent, sign-in is unchanged.

### Dashboard widget

Recording Studio Dashboard is optional. This gem does not depend on it. When
that gem is loaded, onboarding registers the widget `:onboarding_setup`.

```ruby
RecordingStudioDashboard.register(:home) do
  row :setup do
    widget :onboarding_setup, span: 6, config: {
      checklist: :studio,
      title: ->(context) { "Finish #{context.studio_name}" },
      link: "/onboarding/setup/studio",
      subject: ->(context) { context.workspace }
    }
  end
end
```

`checklist` is the registered name. The widget calls `setup_status` for that
name and draws one title and one subtitle, then the items still left. The
title is the checklist title. A `title` string or Proc replaces that title.
The subtitle stays the checklist subtitle. Leave the dashboard row untitled.
A row title is a second heading. Each item keeps its link. "See your setup"
opens the full setup page. Pass `link` when that destination should be
somewhere else.

`title` and `link` are a String or a Proc of the dashboard context. `subject`
is the record passed to `setup_status`, or a Proc of the dashboard context
that returns that record. Use it for a workspace or subject checklist. The
person is `context.actor` when the context responds to `actor`. Otherwise the
context itself is the person.

The widget stays off the dashboard when the checklist does not apply, and when
every item is done. Pass `show_complete: true` to keep the finished state
visible. Access still uses Accessible `:view` inside `setup_status`. A person
without access does not see the widget.

The setup page still computes live. The widget reads the saved status and
enqueues a recheck when that row is older than `setup_recheck_interval`.

## Using setup status in your host

`RecordingStudioOnboarding.setup_status` is the call. The setup page and the
admin lookup render this `SetupStatus`.

```ruby
status = RecordingStudioOnboarding.setup_status(:studio, actor: current_user)
status.title
status.subtitle
status.applicable?
status.complete?
status.remaining
status.done
status.to_h
```

A `:user` checklist uses the signed-in person. Pass `subject:` for a workspace
or subject checklist. That person needs Accessible `:view` on the subject.
Anyone else gets `RecordingStudioOnboarding::Unauthorized`.

The first call computes and saves. A later call returns the saved row and
enqueues a recheck when the row is older than `setup_recheck_interval`. Item
`link` values on the status are strings. A zero-argument link callable runs
with `main_app` set to the application route helpers, including from a sign-in
callback or an MCP tool. A callable that takes arguments receives the actor
and the scope target.

After sign-in, pass the full `to_h` as the prompt. `checklist`, `title`,
`subtitle`, `applicable`, and `complete` are always present. Each item
includes `key`. `only` and `except` choose among `next_step`, `icon`, and
`link`. `except: [:key]` raises `ArgumentError`. An unknown field name raises
`ArgumentError`.

```ruby
status = RecordingStudioOnboarding.setup_status(:studio, actor: current_user)
prompt = status.to_h unless status.complete?
```

`to_h` and `as_json` return string keys and plain values. The saved row keeps
the path. Pass `url_options:` when you want an absolute link in that hash.
An `http` or `https` link stays as stored. A nil link stays nil. Omit
`url_options` and a host in `Rails.application.routes.default_url_options`
is used. With no host, the path stays relative. Pass `port` when it is not
80 or 443.

```ruby
def instructions_suffix
  RecordingStudioOnboarding.setup_status(:studio, actor: current_user).to_h(
    except: [:icon],
    url_options: { host: "app.example", protocol: "https" }
  )
end
```

```json
{
  "checklist": "studio",
  "title": "Finish your studio",
  "subtitle": "Here's what's left.",
  "applicable": true,
  "complete": false,
  "remaining": [
    {
      "key": "profile",
      "next_step": "Add your profile",
      "link": "https://app.example/"
    }
  ],
  "done": []
}
```

Run the `create_recording_studio_onboarding_setup_checks` migration. See
`MIGRATION_NOTES.md`.

## Admin integration

When `recording_studio_admin` is present, the engine registers (soft optional):

- Section `onboarding`
- Screens: `onboarding_flows`, `onboarding_previews`, `onboarding_runs`,
  `onboarding_funnel`, `onboarding_provisioning`, `onboarding_checklists`
- Lookup: `/onboarding/admin/setup_lookup` for one account's user-scoped checklist
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
`step.completed`, `step.skipped`, `flow.completed`, `flow.dismissed`, `flow.reset`,
`setup.completed`, `setup.regressed`.

## RecordingStudio_users integration

Requires **RecordingStudio_users >= 0.30.0**, **< 1.0**.

Subscribes to `registration.completed.recording_studio_user` for every
successful sign-up method (`:password`, `:oauth`, `:otp`). Provisioning is
idempotent per actor, so duplicate events do not double-provision.

The older OTP-only event (`otp.registration_completed.recording_studio_user`)
is not subscribed; OTP is covered by the unified event.

Users does not publish a sign-in event. Setup rechecks on sign-in use
`Warden::Manager.after_authentication` when Warden is loaded. That hook enqueues
user-scoped checklists and any saved rows for other scopes. Each recheck still
obeys `setup_recheck_interval`.

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
  `v0.16.0`, Flatpack `v0.1.377`. The dummy also pins Dashboard `v0.5.0`.
  The gem does not depend on Dashboard.
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
