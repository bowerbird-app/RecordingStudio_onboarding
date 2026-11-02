# frozen_string_literal: true

require "recording_studio_onboarding/config_loader"
require "recording_studio_onboarding/extension_applier"

module RecordingStudioOnboarding
  class Engine < ::Rails::Engine
    isolate_namespace RecordingStudioOnboarding

    class << self
      def apply_model_extensions(target)
        ExtensionApplier.apply_model(target)
      end

      def apply_controller_extensions(target)
        ExtensionApplier.apply_controller(target)
      end
    end

    initializer "recording_studio_onboarding.before_initialize",
                before: "recording_studio_onboarding.load_config" do |_app|
      RecordingStudioOnboarding.configuration.hooks.run(:before_initialize, self)
    end

    initializer "recording_studio_onboarding.load_config" do |app|
      ConfigLoader.call(app)
    end

    initializer "recording_studio_onboarding.after_initialize",
                after: "recording_studio_onboarding.load_config" do |_app|
      RecordingStudioOnboarding.configuration.hooks.run(:after_initialize, self)
    end

    initializer "recording_studio_onboarding.users_registration_integration" do
      config.after_initialize do
        RecordingStudioOnboarding::UsersRegistrationIntegration.install!
      end
    end

    # Soft optional: register RS Terms Agree gate when that gem is loaded.
    # No gemspec dependency — detection is defined?(RecordingStudioTermsAndConditions).
    initializer "recording_studio_onboarding.register_terms_gate" do
      config.after_initialize do
        RecordingStudioOnboarding::Gates::TermsAndConditions.register_if_present!
      end
    end

    # Soft register with RecordingStudioAdmin when the host mounts it.
    # register! is idempotent; Admin's registry replaces Zeitwerk-reloaded classes.
    initializer "recording_studio_onboarding.register_admin" do
      config.to_prepare do
        next unless defined?(RecordingStudioAdmin)

        require "recording_studio_onboarding/admin"
        next unless RecordingStudioOnboarding::Admin.respond_to?(:register!)

        RecordingStudioOnboarding::Admin.register!
      end
    end

    initializer "recording_studio_onboarding.apply_model_extensions" do
      config.to_prepare do
        next unless defined?(ActiveRecord::Base)

        ActiveRecord::Base.descendants.each do |model|
          next if model.abstract_class?

          RecordingStudioOnboarding::Engine.apply_model_extensions(model)
        end
      end
    end

    initializer "recording_studio_onboarding.apply_controller_extensions" do
      config.to_prepare do
        next unless defined?(ActionController::Base)

        ActionController::Base.descendants.each do |controller|
          RecordingStudioOnboarding::Engine.apply_controller_extensions(controller)
        end
      end
    end
  end
end
