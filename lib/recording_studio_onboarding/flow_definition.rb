# frozen_string_literal: true

require "recording_studio_onboarding/step_definition"

module RecordingStudioOnboarding
  # Immutable-ish configuration object for a named onboarding flow.
  class FlowDefinition
    SCOPES = %i[user workspace subject].freeze
    # Line progress only — numbered segment headers were removed.
    PROGRESS_MODES = %i[bar].freeze
    BUTTON_POSITIONS = %i[left right full].freeze

    attr_reader :key, :steps

    def initialize(key)
      @key = key.to_sym
      @scope = :user
      @progress = :bar
      @dismissible = true
      @version = 1
      @steps = []
      @after_complete = nil
      @after_dismiss = nil
    end

    def scope(value = nil)
      return @scope if value.nil?

      scope_key = value.to_sym
      raise ArgumentError, "Unsupported scope #{value.inspect}" unless SCOPES.include?(scope_key)

      @scope = scope_key
    end

    def progress(value = nil)
      return @progress if value.nil?

      mode = value.to_sym
      unless PROGRESS_MODES.include?(mode)
        raise ArgumentError,
              "Unsupported progress #{value.inspect}. " \
              "Numbered segment headers were removed; use :bar."
      end

      @progress = mode
    end

    def dismissible(value = nil)
      return @dismissible if value.nil?

      @dismissible = !!value
    end

    def version(value = nil)
      return @version if value.nil?

      @version = Integer(value)
    end

    def after_complete(value = nil)
      return @after_complete if value.nil?

      @after_complete = value
    end

    def after_dismiss(value = nil)
      return @after_dismiss if value.nil?

      @after_dismiss = value
    end

    def step(key, component:, **)
      raise ArgumentError, "step key is required" if key.blank?
      raise ArgumentError, "step component is required" if component.blank?

      @steps << StepDefinition.build(key, component: component, **)
    end

    def step_keys
      @steps.map(&:key)
    end

    def step_for(key)
      @steps.find { |step| step.key == key.to_sym }
    end

    def first_step_key
      @steps.first&.key
    end

    def visible_steps
      @steps.select(&:show_progress?)
    end

    def freeze_definition!
      @steps.each(&:freeze)
      @steps.freeze
      freeze
    end
  end
end
