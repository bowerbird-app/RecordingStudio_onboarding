# frozen_string_literal: true

require "recording_studio_onboarding/checklist_definition"
require "recording_studio_onboarding/flow_definition"

module RecordingStudioOnboarding
  class Configuration
    attr_reader :hooks, :provisioners, :flows, :checklists, :before_onboarding_gates, :layout
    attr_accessor :authorize_run, :preview_context, :current_actor, :setup_recheck_interval

    def initialize
      @hooks = RecordingStudio::Hooks.new
      @provisioners = {}
      @flows = {}
      @checklists = {}
      @before_onboarding_gates = []
      @authorize_run = nil
      @preview_context = nil
      @current_actor = nil
      @layout = nil
      @setup_recheck_interval = 5.minutes
    end

    def layout=(value)
      @layout = RecordingStudio::Layout.accept(value)
    end

    # Register a callable (or object responding to #call) that runs before the
    # user-facing onboarding UI. Signature:
    #
    #   call(controller:, actor:, return_path:) → redirect path or nil
    #
    # First non-nil path wins. Provisioning is not gated.
    def before_onboarding(gate = nil, &block)
      callable = gate || block
      raise ArgumentError, "before_onboarding gate or block is required" if callable.nil?
      raise ArgumentError, "before_onboarding gate must respond to #call" unless callable.respond_to?(:call)

      @before_onboarding_gates << callable
      callable
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
    #     progress :bar
    #     dismissible true
    #     version 1
    #     step :welcome,
    #       component: "Dummy::Onboarding::WelcomeComponent",
    #       controls: %i[continue]
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

    # Register a named setup checklist. Separate from flows.
    #
    #   config.checklist :studio do
    #     scope :user
    #     title "Finish your studio" # optional, default "Your setup"
    #     subtitle remaining: "Here's what's left." # optional string, states, or callable
    #     item :profile,
    #       check: ->(actor, scope) { actor.email.present? },
    #       next_step: "Confirm the email on your account",
    #       link: "https://example.com/profile"
    #   end
    def checklist(name, &block)
      raise ArgumentError, "checklist name is required" if name.blank?
      raise ArgumentError, "checklist definition block is required" unless block

      definition = ChecklistDefinition.new(name)
      definition.instance_eval(&block)
      raise ArgumentError, "checklist #{name.inspect} must declare at least one item" if definition.items.empty?

      @checklists[name.to_sym] = definition.freeze_definition!
    end

    def checklist_for(name)
      @checklists[name.to_sym]
    end

    def checklist_registered?(name)
      @checklists.key?(name.to_sym)
    end

    def delete_checklist(name)
      @checklists.delete(name.to_sym)
    end

    def clear_flows
      @flows = {}
    end

    def delete_flow(name)
      @flows.delete(name.to_sym)
    end

    def to_h
      {
        provisioners: @provisioners.keys,
        flows: @flows.keys,
        checklists: @checklists.keys,
        setup_recheck_interval: @setup_recheck_interval,
        before_onboarding_gates: @before_onboarding_gates.size,
        hooks_registered: @hooks.registered_counts
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
