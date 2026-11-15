# Recording Studio kit pin update

Copied addons now start on the Support host-kit floor.

- Gemspec: `add_dependency "recording_studio", ">= 7.0", "< 8.0"`
- Dummy and root GitHub tags (from the Gemfiles): Recording Studio `v7.0.0`, Accessible `v0.44.0`, Admin `v2.16.0`, API `v0.24.0`, Attachable `v0.28.0`, Cache `v0.6.3`, Icons `v0.2.1`, Logs `v0.8.0`, RecordingStudio_users `v0.30.0`, Metrics `v0.9.0`, Moveable `v5.0.0`, Trashable `v0.17.0`, Root Switchable `v0.15.1`, FlatPack `v0.1.376`. Dummy omits Terms and Publishable until Terms ships a core 7 tag. Gemspec: `recording_studio` `>= 7.0`, `< 8.0`, `recording_studio_user` `>= 0.30.0`, `< 1.0`.
- Root and dummy Rails locks both `8.1.4`
- Authenticated dummy layout: `recording_studio_layout` plus FlatPack CSS/JS
- Hooks and BaseService come from core; do not copy them into a new addon
- Recordable declarations remain required
- Optional example mixin: `include RecordingStudio::Capabilities::Example.to(**opts)` wraps `RecordingStudio::Capabilities.include_for`. Installing the gem does not enable it globally.
