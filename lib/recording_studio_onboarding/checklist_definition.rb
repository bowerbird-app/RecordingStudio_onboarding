# frozen_string_literal: true

require "recording_studio_onboarding/checklist_item"
require "recording_studio_onboarding/flow_definition"

module RecordingStudioOnboarding
  class ChecklistDefinition
    SCOPES = FlowDefinition::SCOPES

    attr_reader :key, :items

    def initialize(key)
      @key = key.to_sym
      @scope = :user
      @applies_to = nil
      @items = []
    end

    def scope(value = nil)
      return @scope if value.nil?

      scope_key = value.to_sym
      raise ArgumentError, "Unsupported scope #{value.inspect}" unless SCOPES.include?(scope_key)

      @scope = scope_key
    end

    def applies_to(callable = nil, &block)
      chosen = callable || block
      return @applies_to if chosen.nil?

      raise ArgumentError, "applies_to must respond to #call" unless chosen.respond_to?(:call)

      @applies_to = chosen
    end

    def item(key, check:, next_step:, link:, applies_to: nil, icon: nil) # rubocop:disable Metrics/ParameterLists
      built = ChecklistItem.build(
        key, check: check, next_step: next_step, link: link, applies_to: applies_to, icon: icon
      )
      raise ArgumentError, "duplicate item key #{built.key.inspect}" if item_for(built.key)

      @items << built
    end

    def item_for(key)
      @items.find { |item| item.key == key.to_sym }
    end

    def freeze_definition!
      @items.freeze
      freeze
    end
  end
end
