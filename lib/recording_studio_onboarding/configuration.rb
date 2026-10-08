# frozen_string_literal: true

module RecordingStudioOnboarding
  class Configuration
    attr_reader :hooks, :provisioners

    def initialize
      @hooks = RecordingStudio::Hooks.new
      @provisioners = {}
    end

    # Register a named provisioning handler.
    #
    #   config.provision :new_registration, with: "Dummy::ProvisionRegistration"
    #
    # +with+ may be a class, a class name String, or any object that responds to +.call+.
    def provision(name, with:)
      raise ArgumentError, "provisioner name is required" if name.blank?
      raise ArgumentError, "provisioner :with is required" if with.nil?

      @provisioners[name.to_sym] = with
    end

    def provisioner_for(name)
      @provisioners[name.to_sym]
    end

    def provisioner_registered?(name)
      @provisioners.key?(name.to_sym)
    end

    def to_h
      {
        provisioners: @provisioners.keys,
        hooks_registered: @hooks.instance_variable_get(:@registry).transform_values(&:size)
      }
    end

    def merge!(hash)
      return unless hash.respond_to?(:each)

      hash.each do |key, value|
        setter = "#{key}="
        public_send(setter, value) if respond_to?(setter)
      end
    end
  end
end
