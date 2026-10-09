# Dummy App

This Rails app exists to validate the Recording Studio addon template in a real host application.

## What It Covers

- RecordingStudio_users auth at `/users/sign_up` and `/users/sign_in` (Devise
  actor + People/Profile), with a seeded admin user; OTP off so OTP paths 404
- Onboarding provisioning from `registration.completed.recording_studio_user`
- Soft RS Terms & Conditions (`v0.9.0`) + Publishable (`v0.4.2`): seeded live
  Terms; Agree runs before user-facing onboarding when acceptance is due
- `Current.actor` wiring for Recording Studio events
- Root workspace plus seeded folder and page recordables
- Recording Studio default layout, FlatPack assets, and Tailwind source scanning
- Mounted `RecordingStudio::Engine` route behavior inside a host app
- Dummy-only `/docs/*` pages for gem-specific onboarding

## Quick Start

```bash
cd test/dummy
bundle install
bin/rails db:setup
bin/dev
```

Run the commands above from the dummy app directory, not the repository root.

Then open the app and sign in with:

- Email: `admin@admin.com`
- Password: `Password`

## Useful Routes

- `/` - dummy app home page and template guidance
- `/flows` - start registered flows; embedded RunComponent when active
- `/onboarding/runs/:uuid` - full-screen card shell for the current step
- `/recording_studio_terms_and_conditions/acceptance` - Agree (terms-before-onboarding)
- `/admin` - RecordingStudio Admin root (onboarding section + screens)
- `/admin/root` - host admin landing with search
- `/onboarding/admin/previews/:flow/:step` - card preview (writes nothing)
- `/provisioning` - provisioning execution status
- `/recording_studio` - redirects to `/` while the mounted Recording Studio engine stays available under that prefix for non-root routes
- `/users/sign_in` / `/users/sign_up` - RecordingStudio_users auth screens
- `/recording_studio_users` - mounted Users engine (profile / admin)
- `/docs/install`, `/docs/config`, `/docs/recordable_types`, `/docs/recordings_tree`, `/docs/gem_views`, `/docs/methods` - dummy-only starter pages
- `/up` - Rails health check

## Why This App Exists

Use this app to verify the generated addon experience before renaming the gem or copying patterns into another host app. If a layout, route, asset source, or Recording Studio initializer change breaks here, the template likely needs adjustment before reuse.

Authenticated pages use Recording Studio's shared default layout. Devise sign-in keeps `layouts/application`. Replace dummy docs page content so it matches the gem's actual concepts.

The home page in `app/views/home/index.html.erb` should stay a minimal demo surface for the gem's core feature. Do not turn it into a wall of documentation; the dummy docs pages exist so deeper explanations can live in focused sections.
