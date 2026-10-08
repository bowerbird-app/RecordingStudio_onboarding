# frozen_string_literal: true

module RecordingStudioOnboarding
  module Admin
    class PreviewsController < BaseController
      def show
        before_count = FlowRun.count
        @run = RecordingStudioOnboarding.preview(params[:flow_key], params[:step_key])
        after_count = FlowRun.count
        raise "preview wrote FlowRun rows" if after_count != before_count

        @card = render_card_component
      rescue KeyError => e
        render plain: e.message, status: :not_found
      end

      private

      def render_card_component
        step = @run.current_step
        component_class = step.component.to_s.constantize
        component_class.new(run: @run, step: step)
      end
    end
  end
end
