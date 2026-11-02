# frozen_string_literal: true

module RecordingStudioOnboarding
  # Loads optional host YAML / config.x into Configuration. Missing YAML is
  # ignored; other boot errors raise.
  class ConfigLoader
    MISSING_YAML = /Could not load configuration\. No such file/

    def self.call(app)
      new(app).call
    end

    def initialize(app)
      @app = app
    end

    def call
      merge_yaml!
      merge_x_config!
      RecordingStudioOnboarding.configuration.hooks.run(
        :on_configuration,
        RecordingStudioOnboarding.configuration
      )
    end

    private

    def merge_yaml!
      return unless @app.respond_to?(:config_for)

      yaml = @app.config_for(:recording_studio_onboarding)
      RecordingStudioOnboarding.configuration.merge!(yaml) if yaml.respond_to?(:each)
    rescue RuntimeError => e
      raise unless MISSING_YAML.match?(e.message)
    end

    def merge_x_config!
      return unless x_config

      hash = x_config_hash
      RecordingStudioOnboarding.configuration.merge!(hash) if hash.respond_to?(:each)
    end

    def x_config
      return unless @app.config.respond_to?(:x)
      return unless @app.config.x.respond_to?(:recording_studio_onboarding)

      @app.config.x.recording_studio_onboarding
    end

    def x_config_hash
      return x_config.to_h if x_config.respond_to?(:to_h)
      return unless x_config.respond_to?(:each_pair)

      hash = {}
      x_config.each_pair { |key, value| hash[key] = value }
      hash
    end
  end
end
