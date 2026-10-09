# frozen_string_literal: true

module RecordingStudioOnboarding
  class Engine < ::Rails::Engine # rubocop:disable Metrics/ClassLength
    isolate_namespace RecordingStudioOnboarding

    class << self
      def apply_model_extensions(target)
        apply_extensions(target, extensions_for(:model, extension_keys_for(target)))
      end

      def apply_controller_extensions(target)
        apply_extensions(target, extensions_for(:controller, extension_keys_for(target)))
      end

      private

      def extensions_for(kind, names)
        hooks = RecordingStudioOnboarding.configuration.hooks
        Array(names).flat_map do |name|
          if kind == :model
            hooks.model_extensions_for(name)
          else
            hooks.controller_extensions_for(name)
          end
        end
      end

      def apply_extensions(target, extensions)
        return unless target

        applied = target.instance_variable_get(:@recording_studio_onboarding_applied_extensions) || identity_hash

        extensions.flatten.compact.each do |extension|
          next if applied[extension]

          target.class_eval(&extension)
          applied[extension] = true
        end

        target.instance_variable_set(:@recording_studio_onboarding_applied_extensions, applied)
      end

      def extension_keys_for(target)
        names = [target.name, target.name&.demodulize].compact.uniq
        names.map(&:to_sym)
      end

      def identity_hash
        {}.compare_by_identity
      end
    end

    initializer "recording_studio_onboarding.before_initialize",
                before: "recording_studio_onboarding.load_config" do |_app|
      RecordingStudioOnboarding.configuration.hooks.run(:before_initialize, self)
    end

    initializer "recording_studio_onboarding.load_config" do |app|
      if app.respond_to?(:config_for)
        begin
          yaml = begin
            app.config_for(:recording_studio_onboarding)
          rescue StandardError
            nil
          end
          RecordingStudioOnboarding.configuration.merge!(yaml) if yaml.respond_to?(:each)
        rescue StandardError => _e
          # ignore load errors; host app can provide initializer overrides
        end
      end

      if app.config.respond_to?(:x) && app.config.x.respond_to?(:recording_studio_onboarding)
        xcfg = app.config.x.recording_studio_onboarding
        if xcfg.respond_to?(:to_h)
          RecordingStudioOnboarding.configuration.merge!(xcfg.to_h)
        else
          begin
            hash = {}
            xcfg.each_pair { |k, v| hash[k] = v } if xcfg.respond_to?(:each_pair)
            RecordingStudioOnboarding.configuration.merge!(hash) if hash&.any?
          rescue StandardError => _e
            # ignore
          end
        end
      end

      RecordingStudioOnboarding.configuration.hooks.run(:on_configuration, RecordingStudioOnboarding.configuration)
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
    # Controllers also live under RecordingStudioOnboarding::Admin; load (not
    # require) so register! is redefined after Zeitwerk reloads that namespace.
    initializer "recording_studio_onboarding.register_admin" do
      config.to_prepare do
        next unless defined?(RecordingStudioAdmin)

        load File.expand_path("admin.rb", __dir__)
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
