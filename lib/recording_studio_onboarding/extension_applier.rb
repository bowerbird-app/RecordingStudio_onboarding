# frozen_string_literal: true

module RecordingStudioOnboarding
  # Applies host-registered model and controller extension blocks once per class.
  class ExtensionApplier
    def self.apply_model(target)
      new(target, :model).apply
    end

    def self.apply_controller(target)
      new(target, :controller).apply
    end

    def initialize(target, kind)
      @target = target
      @kind = kind
    end

    def apply
      return unless @target

      extensions.flatten.compact.each { |extension| apply_one(extension) }
      @target.instance_variable_set(:@recording_studio_onboarding_applied_extensions, applied)
    end

    private

    def extensions
      hooks = RecordingStudioOnboarding.configuration.hooks
      extension_keys.flat_map do |name|
        if @kind == :model
          hooks.model_extensions_for(name)
        else
          hooks.controller_extensions_for(name)
        end
      end
    end

    def extension_keys
      names = [@target.name, @target.name&.demodulize].compact.uniq
      names.map(&:to_sym)
    end

    def apply_one(extension)
      return if applied[extension]

      @target.class_eval(&extension)
      applied[extension] = true
    end

    def applied
      @applied ||= @target.instance_variable_get(:@recording_studio_onboarding_applied_extensions) ||
                   {}.compare_by_identity
    end
  end
end
