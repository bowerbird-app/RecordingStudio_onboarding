# frozen_string_literal: true

require "recording_studio_onboarding/checklist_item"
require "recording_studio_onboarding/flow_definition"

module RecordingStudioOnboarding
  class ChecklistDefinition
    SCOPES = FlowDefinition::SCOPES

    DEFAULT_TITLE = "Your setup"
    DEFAULT_SUBTITLES = {
      remaining: "What to do next.",
      complete: "You're all set.",
      not_applicable: "Nothing here applies to you."
    }.freeze

    attr_reader :key, :items

    def initialize(key)
      @key = key.to_sym
      @scope = :user
      @applies_to = nil
      @items = []
      @title = nil
      @subtitle = nil
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

    def title(value = nil)
      return @title || DEFAULT_TITLE if value.nil?

      raise ArgumentError, "title is required" if value.blank?

      @title = value.to_s
    end

    def subtitle(text = nil, remaining: nil, complete: nil, not_applicable: nil, &block)
      spec = block || text
      states = { remaining:, complete:, not_applicable: }.compact
      raise ArgumentError, "subtitle takes text, a callable, or per-state text" if spec && states.any?
      raise ArgumentError, "subtitle is required" if spec.nil? && states.empty?

      @subtitle = spec ? subtitle_spec(spec) : subtitle_states(states)
    end

    def subtitle_for(status)
      spec = @subtitle
      return self.class.default_subtitle(status) if spec.nil?
      return spec if spec.is_a?(String)
      return state_subtitle(spec, status) if spec.is_a?(Hash)

      rendered = spec.arity.zero? ? spec.call : spec.call(status)
      raise ArgumentError, "subtitle is required" if rendered.blank?

      rendered.to_s
    end

    def self.default_subtitle(status)
      DEFAULT_SUBTITLES.fetch(subtitle_state(status))
    end

    def self.subtitle_state(status)
      return :not_applicable unless status.applicable?

      status.complete? ? :complete : :remaining
    end

    def freeze_definition!
      @subtitle.freeze if @subtitle.is_a?(Hash)
      @items.freeze
      freeze
    end

    private

    def state_subtitle(spec, status)
      spec.fetch(self.class.subtitle_state(status)) { self.class.default_subtitle(status) }
    end

    def subtitle_spec(spec)
      return required_text(spec) if spec.is_a?(String)
      raise ArgumentError, "subtitle must be text or a callable" unless spec.respond_to?(:call)

      spec
    end

    def subtitle_states(states)
      states.each_value { |text| required_text(text) }
      states.transform_values(&:to_s)
    end

    def required_text(text)
      raise ArgumentError, "subtitle is required" if text.blank?

      text.to_s
    end
  end
end
