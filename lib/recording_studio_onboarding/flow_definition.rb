# frozen_string_literal: true

module RecordingStudioOnboarding
  # Immutable-ish configuration object for a named onboarding flow.
  class FlowDefinition # rubocop:disable Metrics/ClassLength
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

    # rubocop:disable-next Metrics/ParameterLists, Metrics/MethodLength -- step DSL mirrors plan §7
    def step(key, component:, controls: %i[continue], show_progress: true,
             skippable: true, complete_when: nil, button_positions: {})
      raise ArgumentError, "step key is required" if key.blank?
      raise ArgumentError, "step component is required" if component.blank?

      @steps << StepDefinition.new(
        key: key.to_sym,
        component: component,
        controls: normalize_controls(controls),
        show_progress: show_progress,
        skippable: skippable,
        complete_when: complete_when,
        button_positions: normalize_button_positions(button_positions)
      )
    end

    def normalize_controls(controls)
      Array(controls).map(&:to_sym).reject { |control| control == :exit }
    end

    def normalize_button_positions(raw)
      Hash(raw).each_with_object({}) do |(key, value), memo|
        position = value.to_sym
        unless BUTTON_POSITIONS.include?(position)
          raise ArgumentError,
                "Unsupported button position #{value.inspect} " \
                "(expected one of #{BUTTON_POSITIONS.join(', ')})"
        end

        memo[key.to_sym] = position
      end
    end
    private :normalize_controls, :normalize_button_positions

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

    StepDefinition = Struct.new(
      :key, :component, :controls, :show_progress, :skippable, :complete_when,
      :button_positions,
      keyword_init: true
    ) do
      def show_progress?
        show_progress
      end

      def skippable?
        skippable
      end
    end
  end
end
