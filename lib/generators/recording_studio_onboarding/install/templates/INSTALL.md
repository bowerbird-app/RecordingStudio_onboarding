===============================================================================

RecordingStudioOnboarding has been installed successfully!

The engine has been mounted at /onboarding in your application (configurable).

If you use Tailwind CSS:
1. Run 'bin/rails tailwindcss:build' to rebuild your CSS with RecordingStudioOnboarding styles

Next steps:
1. Register provisioners in config/initializers/recording_studio_onboarding.rb
2. Run `bin/rails generate recording_studio_onboarding:migrations`
3. Run `bin/rails db:migrate`
4. Wire auth, layout, and current actor integration in the host app
5. Ensure host recordables declare `recording_studio_recordable` as required
6. With RecordingStudio_users >= 0.15.0, provisioning runs from
   registration.completed.recording_studio_user (password, OAuth, and OTP).
   Call RecordingStudioOnboarding.provision only for custom registration paths
   that do not emit that event.

===============================================================================
