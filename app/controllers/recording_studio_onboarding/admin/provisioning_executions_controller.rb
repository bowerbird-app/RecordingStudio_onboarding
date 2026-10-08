# frozen_string_literal: true

module RecordingStudioOnboarding
  module Admin
    class ProvisioningExecutionsController < BaseController
      before_action :set_execution

      def show; end

      def retry # rubocop:disable Metrics/MethodLength
        return unless authorize_resource_action!("onboarding_provisioning", :retry, @execution)

        unless @execution.failed?
          return redirect_to(
            admin_provisioning_execution_path(@execution),
            alert: "Only failed executions can be retried."
          )
        end

        perform_retry!
        @execution.reload
        redirect_to admin_provisioning_execution_path(@execution), notice: "Provisioning retried."
      rescue StandardError => e
        redirect_to admin_provisioning_execution_path(@execution), alert: e.message
      end

      def perform_retry! # rubocop:disable Metrics/MethodLength
        perform_recording_studio_admin_action!(
          "onboarding_provisioning",
          :retry,
          @execution,
          audit_action: :retry
        ) do
          RecordingStudioOnboarding.provision(
            @execution.provisioner,
            actor: @execution.actor,
            subject: @execution.subject,
            idempotency_key: @execution.idempotency_key
          )
          true
        end
      end

      private

      def set_execution
        @execution = ProvisioningExecution.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        head :not_found
      end
    end
  end
end
