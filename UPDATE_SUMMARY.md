# Recording Studio kit pin update

Copied addons now start on the Support host-kit floor.

- Gemspec: `add_dependency "recording_studio", "~> 6.1"`
- Dummy and root GitHub tags (from the Gemfiles): Recording Studio `v6.5.0`, Accessible `v0.24.2`, Admin `v2.8.2` (off-policy; leave pinned), Attachable `v0.22.1`, Cache `v0.6.3`, Logs `v0.7.4`, RecordingStudio_users `v0.27.1`, Metrics `v0.7.3`, Trashable `v0.12.3`, Root Switchable `v0.11.7`, FlatPack `v0.1.341`. Dummy omits Terms and Publishable until Terms ships a 6.x-compatible tag. Gemspec: `recording_studio` `~> 6.1`, `recording_studio_user` `>= 0.26.6`.
- Root and dummy Rails locks both `8.1.4`
- Authenticated dummy layout: `recording_studio_layout` plus FlatPack CSS/JS
- Hooks and BaseService come from core; do not copy them into a new addon
- Recordable declarations remain required
- Optional example mixin: `include RecordingStudio::Capabilities::Example.to(**opts)` wraps `RecordingStudio::Capabilities.include_for`. Installing the gem does not enable it globally.
