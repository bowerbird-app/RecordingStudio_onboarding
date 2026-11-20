# Recording Studio kit pin update

Copied addons now start on the Support host-kit floor.

- Gemspec: `add_dependency "recording_studio", ">= 7.0", "< 8.0"`
- Dummy and root GitHub tags (from the Gemfiles): Recording Studio `v7.8.0`, Accessible `v0.58.0`, Admin `v2.20.0`, API `v1.21.2`, Attachable `v0.34.0`, Cache `v0.8.0`, Icons `v0.5.0`, Logs `v0.9.0`, RecordingStudio_users `v0.42.1`, Metrics `v0.10.0`, Moveable `v6.1.0`, Trashable `v1.3.0`, Root Switchable `v0.17.0`, FlatPack `v0.2.0`. The dummy also pins Dashboard `v0.6.0`, Notifications `v0.21.0`, and Notifications email `v0.5.4`. The gem does not depend on Dashboard or Notifications. Dummy omits Terms and Publishable until Terms ships a core 7 tag. Gemspec: `recording_studio` `>= 7.0`, `< 8.0`, `recording_studio_user` `>= 0.30.0`, `< 1.0`.
- Root and dummy Rails locks both `8.1.4`
- Authenticated dummy layout: `recording_studio_layout` plus FlatPack CSS/JS
- Hooks and BaseService come from core; do not copy them into a new addon
- Recordable declarations remain required
- Optional example mixin: `include RecordingStudio::Capabilities::Example.to(**opts)` wraps `RecordingStudio::Capabilities.include_for`. Installing the gem does not enable it globally.
