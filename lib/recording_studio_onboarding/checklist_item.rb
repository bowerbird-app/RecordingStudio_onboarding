# frozen_string_literal: true

module RecordingStudioOnboarding
  class ChecklistItem < Data.define(:key, :check, :next_step, :link, :applies_to)
    ABSOLUTE_HTTP = %r{\Ahttps?://}i

    def self.build(key, check:, next_step:, link:, applies_to: nil)
      validate!(key, check, next_step, link, applies_to)
      new(
        key: key.to_sym,
        check: check,
        next_step: next_step.to_s,
        link: link,
        applies_to: applies_to
      )
    end

    def self.absolute_http?(value)
      value.is_a?(String) && ABSOLUTE_HTTP.match?(value)
    end

    def self.validate!(key, check, next_step, link, applies_to)
      raise ArgumentError, "item key is required" if key.blank?
      raise ArgumentError, "item check must respond to #call" unless check.respond_to?(:call)
      raise ArgumentError, "item next_step is required" if next_step.blank?

      validate_link!(link)
      return if applies_to.nil? || applies_to.respond_to?(:call)

      raise ArgumentError, "item applies_to must respond to #call"
    end

    def self.validate_link!(link)
      return if link.respond_to?(:call)
      return if absolute_http?(link)

      raise ArgumentError, "item link must be an absolute http(s) URL or a callable"
    end
    private_class_method :validate!, :validate_link!
  end
end
