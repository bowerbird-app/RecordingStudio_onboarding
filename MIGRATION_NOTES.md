# Migration Notes

## Current Requirements

- Ruby 3.3 or newer
- Rails 8.1 or newer
- Recording Studio `>= 7.0`, `< 8.0` (dummy GitHub tag `v7.8.0`)
- RecordingStudio_users `>= 0.30.0`, `< 1.0` (dummy/root GitHub tag `v0.41.0`)
  for the registration-completed provisioning subscriber; dummy mounts users auth
- RecordingStudio_metrics `v0.10.0`
- Accessible dummy tag `v0.58.0`, Attachable `v0.34.0`, Admin `v2.20.0`,
  Dashboard `v0.6.0` (dummy only; the gem does not depend on it),
  API `v1.21.2` (`require: false`), Moveable `v6.1.0` (`require: false`),
  Icons `v0.5.0` (`require: false`), Cache `v0.8.0`, Logs `v0.9.0`,
  Trashable `v1.3.0` (dummy `purge_at` column; kept rows use `Recording.kept`),
  Root Switchable `v0.17.0`
- FlatPack dummy tag `v0.2.0` (`view_component` `>= 4.14.0`, `< 5`). Icons are
  server-rendered. Do not pin `flat_pack/heroicons` or register `flat-pack--icon`.
- Dummy and `gemfiles/without_terms.gemfile` omit Terms and Publishable.
  Agree-before-onboarding is tested once Terms ships a core 7 tag.
- Dummy Puma `8.1.1` and msgpack `>= 1.8.7`
- Public RubyGems and GitHub access for dependency installation

## 0.11.0 Dependency pins

- No onboarding migration. Gemspec floors stay `recording_studio` `>= 7.0`,
  `< 8.0` and `recording_studio_user` `>= 0.30.0`, `< 1.0`.
- Hosts MUST run the Recording Studio 7.4, 7.5 and 7.7 migrations if they have not.
- flat_pack 0.2.0 is supported; hosts moving to 0.2 must remove the manual
  `flat_pack/heroicons` importmap pin and any `flat-pack--icon` controller
  registration. Unknown icon names raise in development and test.
- Dummy copies the Users sign-in lockout and sign-in link migrations from
  Users `v0.41.0`. Hosts that mount Users should run those Users migrations.
- Users 0.41 removes `after_sign_up_path_for` from `Auth::BaseController`.
  Drop a host `public :after_sign_in_path_for, :after_sign_up_path_for`
  workaround. The dummy no longer publishes those methods.

## 0.10.0 Dashboard widget

- No migration. Flows, provisioning, checklist keys, and in-progress runs stay
  as they are.
- Recording Studio Dashboard is optional. The gem does not depend on it. When
  the host has loaded that gem, onboarding registers `:onboarding_setup`.
- Place it with a `checklist` name. The widget calls `setup_status` (the saved
  row, then a recheck when the row is stale) and shows the remaining items.
  It does not draw a heading. Set the section title on the dashboard row.
  "See your setup" links to the setup page. `link` is a String or a Proc of
  the dashboard context. `subject` is a record or a Proc of that context.
- The widget is omitted when the checklist does not apply or is complete.
  `show_complete: true` keeps the finished state. Accessible `:view` is
  unchanged. A person without access does not see the widget.
- The setup page still computes live. The widget uses the saved row and
  enqueues a recheck when it is stale.

## 0.9.1 Your setup column

- The default Your setup page uses `FlatPack::Grid` with `cols: 2`. The
  heading, the remaining list, and the all-done line are the first cell. The
  second column is empty. Below the `md` breakpoint the page is one column.
- No migration. Admin lookup still renders `SetupPageComponent` at the full
  width of that screen.
- Override `app/views/recording_studio_onboarding/setup/show` to keep a
  full-width list.
- `setup_status` returns `title`, `subtitle`, and `to_h` / `as_json`. Call
  the same method the setup page uses. Item links are stored as paths. A
  zero-argument `link` callable uses the application route helpers, so a
  sign-in callback does not pass a controller. `to_h(only:, except:, url_options:)`
  shapes item fields and can build absolute URLs. `key` is always included.
  If `Rails.application.routes.default_url_options` has a host, `to_h` and
  `as_json` return absolute links. The saved row stays a path. No migration.
- Optional `title` and `subtitle` on `config.checklist`. Defaults are
  unchanged: "Your setup", "What to do next.", "You're all set.", and
  "Nothing here applies to you." A subtitle is one string, per-state text,
  or a callable. Pass already translated text if you use I18n.
- The setup page sets `content_for :title` to the checklist title for the
  browser tab. It also sets `content_for :hide_layout_heading` so the default
  layout does not draw that heading a second time. A host layout that replaces
  `recording_studio/shared/_default_layout` should do the same.

## 0.9.0 Setup checklists

- Copy `db/migrate/20261118120000_create_recording_studio_onboarding_setup_checks.rb`
  into the host (the install generator does this for a new install) and migrate.
  The table is `recording_studio_onboarding_setup_checks`.
- Existing flows, gates, events, and routes are unchanged. Checklists are
  additive. They do not gate provisioning.
- Set `config.setup_recheck_interval` if 5 minutes is the wrong throttle.
- Sign-in rechecks need Warden. Hosts without Warden keep the page and
  `setup_status` recheck, and skip the sign-in hook.
- Item `link` is the page where the person does that step. Pass a path, an
  absolute URL, or `link: -> { main_app.new_press_kit_path }`. Optional `icon:`
  is a FlatPack icon name. The setup page shows only what is left.

## 0.8.0 Recording Studio 7

- The gemspec requires Recording Studio `>= 7.0`, `< 8.0` and
  RecordingStudio_users `>= 0.30.0`, `< 1.0`.
- `RecordingStudio.root_recording_for` only finds a root. It returns nil when
  the recordable has none. Create a root with
  `RecordingStudio.create_root_recording!(recordable, actor:)`.
- Copy Recording Studio's `events.root_recording_id` migration
  (`20261114090000`) into the host and migrate before booting 0.8.0.
- Admin 2.16 dropped `site_admin_recording_resolver`. Set
  `access_recording_resolver` and read kept rows with `Recording.kept`.
- Dummy `authorize_write` still requires Accessible `:edit`, and allows a new
  root when the write has no recording yet. Onboarding steps still check
  Accessible `:view` on workspace and subject scopes.
- Root Switchable `v0.15.0` declares `recording_studio < 7`. The dummy pin is
  `v0.15.1`, which allows core 7.
- API `v0.24.0` requires Logs `>= 0.8.0`, `< 1.0`. The dummy pin is Logs
  `v0.8.0`.
- Users `v0.30.0` rejects passwords shorter than 12 characters. Seeded and
  test accounts use `Password123!`. Dummy Devise `password_length` is `12..128`.

## 0.7.4 omniauth 2.2.0

- Root, dummy, and without-terms lockfiles pin omniauth 2.2.0
  (CVE-2026-63183). No other locked gems moved. Recording Studio stays
  `v6.7.0`.
- No host change. This gem does not depend on omniauth.

## 0.7.3 core 7 phase 1

- The gemspec allows Recording Studio `>= 6.1` and `< 8.0`. The floor stays
  the previous `~> 6.1` lower bound.
- No host change. Core 7 is allowed. Core 7 is not required. Dummy and root
  locks stay on Recording Studio `v6.7.0`.

## 0.7.1 full-screen frame and Continue

- Full-screen run pages top-align the card at every breakpoint. A taller or
  shorter step no longer moves Back, Skip, or the progress bar.
- Continue is an auto-width button on the right on every step, with more
  space above it. `button_positions` still accepts `:left`, `:right`, and
  `:full`. `:left` and `:full` no longer move or stretch Continue. Back and
  Skip are unchanged.
- No host change is required. Leave existing `button_positions` values in
  place.

## 0.7.0 Accessible scoping

- `start` and `provision` raise `RecordingStudioOnboarding::Unauthorized` when
  the actor lacks Accessible `:view` on the workspace, subject, or root.
  User-scoped flows still match actor identity. Provision no longer skips
  Accessible when `subject` or `root` is the actor.
- `active_run` returns `nil` for those same misses.
- Host `authorize_run` callables only further deny.
- Dummy `/flows` 404s on a workspace or page the actor cannot view.
- Dummy `config.authorize_write` allows Access rows only inside
  `AccessCreationContext`, otherwise Accessible `:edit`.
- Dummy does not prepend Users `Directory.create_user!`. First Profile writes
  still need a Users-owned actor API that v0.27.1 does not provide for OmniAuth
  (and Profile writes are not an AccessCreationContext path).

## 0.6.0 core 6.x family

- Engine controllers call `recording_studio_layout`. Layout lookup is the gem
  `configuration.layout` when it is not `nil`, then
  `RecordingStudio.configuration.layout`, then
  `recording_studio/default_layout`.
- Full-screen run pages still render `recording_studio_onboarding/card_shell`.
- Hosts replace `UsesDefaultLayout` with `recording_studio_layout`.
- Admin dummy pin is `v2.8.2` (policy floor `v2.5.1` cannot resolve core 6.3
  and FlatPack 0.1.341). Install Logs with Admin.
- Terms `v0.14.2` still declares `recording_studio ~> 4.2`. Dummy does not
  install it. Do not patch sibling gemspecs during Bundler resolution.
- The with_terms CI lane is removed until Terms ships a core 6 tag.

## 0.5.0 boot, provision, and test helpers

- `provision` raises `RecordingStudioOnboarding::ProvisionFailed` after it
  records a failed execution. The handler error is `#cause`. Admin retry and
  the registration subscriber still log and swallow unexpected errors so
  sign-up is not broken.
- Optional `config_for(:recording_studio_onboarding)` still ignores a missing
  YAML file. Other load errors raise.
- Tests: `RecordingStudioOnboarding.reset_for_tests!` and dummy
  `accept_live_terms_for_tests!(actor)` before `sign_in`.

## 0.4.0 chrome / page breaking changes

- Exit control removed from the UI; `dismiss` remains on the API/route.
- `progress :segments` removed — use `:bar` (default). Step 1 shows colored
  progress immediately.
- Back / Skip are permanent plain-text chrome (not bottom buttons). Back uses
  FlatPack `IconComponent` (`chevron-left`) beside the label.
- Prefer `PageComponent` for splash / top-card / plain layouts; set
  `button_positions: { continue: :left|:right|:full }` for Continue placement.
  See `CHANGELOG.md` upgrade notes and `docs/review/`.

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
