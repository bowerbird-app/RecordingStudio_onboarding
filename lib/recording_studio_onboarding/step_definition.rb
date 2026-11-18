# frozen_string_literal: true

module RecordingStudioOnboarding
  STEP_KEYWORDS = %i[
    controls show_progress skippable complete_when button_positions footer_action
  ].freeze
  FOOTER_ACTIONS = %i[continue skip].freeze

  StepDefinition = Struct.new(
    :key, :component, :controls, :show_progress, :skippable, :complete_when,
    :button_positions, :footer_action,
    keyword_init: true
  ) do
    def self.build(key, component:, **options)
      reject_unknown_keywords!(options)
      new(attributes_for(key, component, options))
    end

    def show_progress?
      show_progress
    end

    def skippable?
      skippable
    end

    # True when the bottom button is the skip action. An omitted continue
    # control means there is no footer button, so the top Skip link stays.
    def footer_skips?
      footer_action == :skip && Array(controls).include?(:continue)
    end

    def self.reject_unknown_keywords!(options)
      unknown = options.keys - STEP_KEYWORDS
      raise ArgumentError, "Unknown keywords: #{unknown.map(&:inspect).join(', ')}" if unknown.any?
    end

    def self.attributes_for(key, component, options)
      {
        key: key.to_sym,
        component: component,
        controls: normalize_controls(options.fetch(:controls, %i[continue])),
        show_progress: options.fetch(:show_progress, true),
        skippable: options.fetch(:skippable, true),
        complete_when: options[:complete_when],
        button_positions: normalize_button_positions(options.fetch(:button_positions, {})),
        footer_action: normalize_footer_action(options)
      }
    end

    def self.normalize_footer_action(options)
      raw = options[:footer_action]
      action = (raw || :continue).to_sym
      unless FOOTER_ACTIONS.include?(action)
        raise ArgumentError,
              "Unsupported footer action #{raw.inspect} " \
              "(expected one of #{FOOTER_ACTIONS.join(', ')})"
      end

      skippable = options.fetch(:skippable, true)
      raise ArgumentError, "footer_action :skip requires a skippable step" if action == :skip && !skippable

      action
    end

    def self.normalize_controls(controls)
      Array(controls).map(&:to_sym).reject { |control| control == :exit }
    end

    def self.normalize_button_positions(raw)
      Hash(raw).each_with_object({}) do |(key, value), memo|
        position = value.to_sym
        unless FlowDefinition::BUTTON_POSITIONS.include?(position)
          raise ArgumentError,
                "Unsupported button position #{value.inspect} " \
                "(expected one of #{FlowDefinition::BUTTON_POSITIONS.join(', ')})"
        end

        memo[key.to_sym] = position
      end
    end
  end
end
