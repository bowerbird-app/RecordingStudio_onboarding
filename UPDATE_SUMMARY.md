# Recording Studio kit pin update

Copied addons now start on the Support host-kit floor.

- Gemspec: `add_dependency "recording_studio", "~> 4.2"`
- Dummy and root GitHub tags (from the Gemfiles, unchanged here): Recording Studio `v4.2.2`, Accessible `v0.11.1`, Admin `v2.0.5`, Attachable `v0.7.1`, RecordingStudio_users `v0.18.0`, Metrics `v0.2.0`, Root Switchable `v0.5.1`, FlatPack `v0.1.196`. Dummy also pins Publishable `v0.4.2` and Terms & Conditions `v0.9.0`. Gemspec: `recording_studio` `~> 4.2`, `recording_studio_user` `>= 0.18.0`.
- Root and dummy Rails locks both `8.1.4`
- Authenticated dummy layout: `RecordingStudio::UsesDefaultLayout` plus FlatPack CSS/JS
- Hooks and BaseService come from core; do not copy them into a new addon
- Recordable declarations remain required
- Optional example mixin: `include RecordingStudio::Capabilities::Example.to(**opts)` wraps `RecordingStudio::Capabilities.include_for`. Installing the gem does not enable it globally.
