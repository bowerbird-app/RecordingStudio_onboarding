# frozen_string_literal: true

require "recording_studio_onboarding/services/failure_sanitizer"
require "recording_studio_onboarding/setup_snapshot"

module RecordingStudioOnboarding
  module Services
    class EvaluateChecklist
      def self.call(definition, actor:, scope:)
        new(definition, actor: actor, scope: scope).call
      end

      def initialize(definition, actor:, scope:)
        @definition = definition
        @actor = actor
        @scope = scope
      end

      def call
        return hidden_status unless applicable?

        build_status(visible_items)
      end

      def applicable?
        return true if @definition.applies_to.nil?

        guard(true) { truthy?(invoke(@definition.applies_to)) }
      end

      private

      def hidden_status
        empty_status(applicable: false, complete: true)
      end

      def build_status(items)
        done, remaining = items.partition(&:done)
        empty_status(applicable: true, complete: remaining.empty?, next_item: remaining.first, done: done,
                     remaining: remaining)
      end

      def empty_status(applicable:, complete:, next_item: nil, done: [], remaining: [])
        SetupStatus.new(
          checklist: @definition.key, applicable: applicable, complete: complete,
          next_item: next_item, done: done, remaining: remaining, checked_at: nil
        )
      end

      def visible_items
        @definition.items.filter_map { |item| evaluate_item(item) }
      end

      def evaluate_item(item)
        return unless show?(item)

        SetupItem.new(key: item.key, next_step: item.next_step, link: link_for(item), done: done?(item))
      end

      def show?(item)
        return true if item.applies_to.nil?

        guard(true) { truthy?(invoke(item.applies_to)) }
      end

      def done?(item)
        guard(false) { truthy?(invoke(item.check)) }
      end

      def link_for(item)
        raw = item.link.respond_to?(:call) ? invoke(item.link) : item.link
        return raw if ChecklistItem.absolute_http?(raw)

        log(ArgumentError.new("checklist item #{item.key} link was not an absolute http(s) URL"))
        nil
      rescue StandardError => e
        log(e)
        nil
      end

      def guard(fallback)
        yield
      rescue StandardError => e
        log(e)
        fallback
      end

      def invoke(callable)
        callable.call(@actor, @scope)
      end

      def truthy?(value)
        value ? true : false
      end

      def log(error)
        return unless defined?(Rails) && Rails.logger

        Rails.logger.warn("[RecordingStudioOnboarding] #{FailureSanitizer.call(error)}")
      end
    end
  end
end
