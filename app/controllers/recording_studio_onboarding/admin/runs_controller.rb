# frozen_string_literal: true

module RecordingStudioOnboarding
  module Admin
    class RunsController < BaseController
      before_action :set_run

      def show
        @step_progresses = @run.step_progresses.order(:created_at)
      end

      def reset
        return unless authorize_resource_action!("onboarding_runs", :reset, @run)

        perform_recording_studio_admin_action!("onboarding_runs", :reset, @run, audit_action: :reset) do
          RecordingStudioOnboarding.reset(@run, actor: current_onboarding_actor)
          true
        end
        redirect_to admin_run_path(@run), notice: "Run reset to the first step."
      end

      def restart
        return unless authorize_resource_action!("onboarding_runs", :restart, @run)

        new_run = nil
        perform_recording_studio_admin_action!("onboarding_runs", :restart, @run, audit_action: :restart) do
          new_run = RecordingStudioOnboarding.restart(@run, actor: current_onboarding_actor)
          true
        end
        redirect_to admin_run_path(new_run), notice: "Started a new run."
      end

      private

      def set_run
        @run = FlowRun.find(params[:uuid] || params[:id])
      rescue ActiveRecord::RecordNotFound
        head :not_found
      end
    end
  end
end
