# frozen_string_literal: true

require "recording_studio_onboarding/flow_definition"

module RecordingStudioOnboarding
  class Configuration
    attr_reader :hooks, :provisioners, :flows
    attr_accessor :authorize_run, :preview_context, :current_actor

    def initialize
      @hooks = RecordingStudio::Hooks.new
      @provisioners = {}
      @flows = {}
      @authorize_run = nil
      @preview_context = nil
      @current_actor = nil
    end

    # Register a named provisioning handler.
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

    # Register a named onboarding flow.
    #
    #   config.flow :account_setup do
    #     scope :user
    #     progress :segments
    #     dismissible true
    #     version 1
    #     step :welcome, component: "Dummy::Onboarding::WelcomeComponent"
    #   end
    def flow(name, &block)
      raise ArgumentError, "flow name is required" if name.blank?
      raise ArgumentError, "flow definition block is required" unless block

      definition = FlowDefinition.new(name)
      definition.instance_eval(&block)
      raise ArgumentError, "flow #{name.inspect} must declare at least one step" if definition.steps.empty?

      @flows[name.to_sym] = definition.freeze_definition!
    end

    def flow_for(name)
      @flows[name.to_sym]
    end

    def flow_registered?(name)
      @flows.key?(name.to_sym)
    end

    def to_h
      {
        provisioners: @provisioners.keys,
        flows: @flows.keys,
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
