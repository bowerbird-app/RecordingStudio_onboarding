# frozen_string_literal: true

module RecordingStudioOnboarding
  class ChecklistItem < Data.define(:key, :check, :next_step, :link, :applies_to, :icon)
    ABSOLUTE_HTTP = %r{\Ahttps?://}i
    DEFAULT_ICON = :queue_list

    def self.build(key, check:, next_step:, link:, applies_to: nil, icon: nil) # rubocop:disable Metrics/ParameterLists
      validate!(key, check, next_step, link, applies_to, icon)
      new(
        key: key.to_sym,
        check: check,
        next_step: next_step.to_s,
        link: link,
        applies_to: applies_to,
        icon: normalize_icon(icon)
      )
    end

    def self.absolute_http?(value)
      value.is_a?(String) && ABSOLUTE_HTTP.match?(value)
    end

    def self.usable_link?(value)
      return false unless value.is_a?(String)

      absolute_http?(value) || value.match?(%r{\A/(?!/)})
    end

    def self.normalize_icon(icon)
      return DEFAULT_ICON if icon.blank?

      icon.to_sym
    end

    def self.validate!(key, check, next_step, link, applies_to, icon) # rubocop:disable Metrics/ParameterLists
      raise ArgumentError, "item key is required" if key.blank?
      raise ArgumentError, "item check must respond to #call" unless check.respond_to?(:call)
      raise ArgumentError, "item next_step is required" if next_step.blank?

      validate_link!(link)
      validate_icon!(icon)
      return if applies_to.nil? || applies_to.respond_to?(:call)

      raise ArgumentError, "item applies_to must respond to #call"
    end

    def self.validate_link!(link)
      return if link.respond_to?(:call)
      return if usable_link?(link)

      raise ArgumentError, "item link must be a path, an absolute http(s) URL, or a callable"
    end

    def self.validate_icon!(icon)
      return if icon.nil? || icon.is_a?(Symbol) || icon.is_a?(String)

      raise ArgumentError, "item icon must be a FlatPack icon name"
    end
    private_class_method :validate!, :validate_link!, :validate_icon!
  end
end
