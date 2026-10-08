# frozen_string_literal: true

module RecordingStudioOnboarding
  module Services
    # Builds an in-memory run-like object for admin card previews.
    # Never persists FlowRun or StepProgress rows.
    class PreviewRun
      PreviewProgress = Struct.new(:step_key, :status, :first_viewed_at, :acted_at, keyword_init: true)

      attr_reader :id, :flow_key, :flow_version, :current_step_key, :status,
                  :scope, :initiating_actor, :step_progresses, :started_at

      def self.call(flow_key:, step_key:, context: nil)
        new(flow_key: flow_key, step_key: step_key, context: context).build
      end

      def initialize(flow_key:, step_key:, context: nil)
        @flow_key = flow_key.to_s
        @step_key = step_key.to_s
        @context = context || resolve_preview_context
      end

      def build
        definition = RecordingStudioOnboarding.configuration.flow_for(@flow_key)
        raise KeyError, "No flow registered for #{@flow_key.inspect}" unless definition
        raise KeyError, "Unknown step #{@step_key.inspect}" unless definition.step_for(@step_key)

        @id = "preview-#{@flow_key}-#{@step_key}"
        @flow_version = definition.version
        @current_step_key = @step_key
        @status = "in_progress"
        @scope = @context[:subject] || @context[:actor]
        @initiating_actor = @context[:actor]
        @started_at = Time.current
        @step_progresses = preview_progresses(definition)
        self
      end

      def definition
        RecordingStudioOnboarding.configuration.flow_for(flow_key)
      end

      def current_step
        definition&.step_for(current_step_key)
      end

      def open? = true
      def preview? = true
      def pending? = false
      def in_progress? = true
      def completed? = false
      def dismissed? = false

      def to_param = id

      def progress_ratio
        visible = definition&.visible_steps || []
        return 0.0 if visible.empty?

        keys = visible.map(&:key)
        index = keys.index(current_step_key.to_sym) || 0
        index.to_f / visible.size
      end

      private

      def resolve_preview_context
        resolver = RecordingStudioOnboarding.configuration.preview_context
        if resolver.respond_to?(:call)
          resolver.call(flow_key: @flow_key, step_key: @step_key).to_h.symbolize_keys
        else
          { actor: nil, subject: nil }
        end
      end

      def preview_progresses(definition)
        keys = definition.step_keys
        current_index = keys.index(@step_key.to_sym) || 0
        keys.each_with_index.map do |key, index|
          status = if index < current_index
                     "completed"
                   else
                     "pending"
                   end
          PreviewProgress.new(step_key: key.to_s, status: status)
        end
      end
    end
  end
end
