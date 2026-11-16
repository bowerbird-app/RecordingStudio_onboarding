# Recording Studio kit pin update

Copied addons now start on the Support host-kit floor.

- Gemspec: `add_dependency "recording_studio", ">= 7.0", "< 8.0"`
- Dummy and root GitHub tags (from the Gemfiles): Recording Studio `v7.3.0`, Accessible `v0.45.1`, Admin `v2.18.0`, API `v1.2.1`, Attachable `v0.31.0`, Cache `v0.7.0`, Icons `v0.4.0`, Logs `v0.8.0`, RecordingStudio_users `v0.32.0`, Metrics `v0.9.0`, Moveable `v6.0.0`, Trashable `v1.0.1`, Root Switchable `v0.16.0`, FlatPack `v0.1.377`. Dummy omits Terms and Publishable until Terms ships a core 7 tag. Gemspec: `recording_studio` `>= 7.0`, `< 8.0`, `recording_studio_user` `>= 0.30.0`, `< 1.0`.
- Root and dummy Rails locks both `8.1.4`
- Authenticated dummy layout: `recording_studio_layout` plus FlatPack CSS/JS
- Hooks and BaseService come from core; do not copy them into a new addon
- Recordable declarations remain required
- Optional example mixin: `include RecordingStudio::Capabilities::Example.to(**opts)` wraps `RecordingStudio::Capabilities.include_for`. Installing the gem does not enable it globally.
