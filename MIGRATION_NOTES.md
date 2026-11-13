# Migration Notes

## Current Requirements

- Ruby 3.3 or newer
- Rails 8.1 or newer
- Recording Studio 6.x (`~> 6.1` in the gemspec; dummy GitHub tag `v6.5.0`)
- RecordingStudio_users `>= 0.26.6` (dummy/root GitHub tag `v0.27.1`) for the
  registration-completed provisioning subscriber; dummy mounts users auth
- RecordingStudio_metrics `v0.7.3`
- Accessible dummy tag `v0.24.2`, Attachable `v0.22.1`, Admin `v2.8.2`
  (off the 2.5.1 host policy; leave pinned), Cache `v0.6.3`, Logs `v0.7.4`,
  Trashable `v0.12.3`, Root Switchable `v0.11.7`
- FlatPack dummy tag `v0.1.341` (`view_component` `>= 4.14`, `< 5`)
- Dummy and `gemfiles/without_terms.gemfile` omit Terms and Publishable.
  Terms `v0.14.2` still declares `recording_studio ~> 4.2`. Agree-before-onboarding
  is tested once Terms ships a 6.x-compatible tag.
- Public RubyGems and GitHub access for dependency installation

## 0.7.1 full-screen frame

- Full-screen run pages top-align the card at every breakpoint. A taller or
  shorter step no longer moves Back, Skip, or the progress bar.
- No host change. Embedded runs are unchanged.

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
