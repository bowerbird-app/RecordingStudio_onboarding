# frozen_string_literal: true

module RecordingStudioOnboarding
  StepDefinition = Struct.new(
    :key, :component, :controls, :show_progress, :skippable, :complete_when,
    :button_positions,
    keyword_init: true
  ) do
    def self.build(key, component:, **options)
      new(
        key: key.to_sym,
        component: component,
        controls: normalize_controls(options.fetch(:controls, %i[continue])),
        show_progress: options.fetch(:show_progress, true),
        skippable: options.fetch(:skippable, true),
        complete_when: options[:complete_when],
        button_positions: normalize_button_positions(options.fetch(:button_positions, {}))
      )
    end

    def show_progress?
      show_progress
    end

    def skippable?
      skippable
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
