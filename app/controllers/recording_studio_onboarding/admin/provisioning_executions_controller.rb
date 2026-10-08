# frozen_string_literal: true

module RecordingStudioOnboarding
  module Admin
    class ProvisioningExecutionsController < BaseController
      before_action :set_execution

      def show; end

      def retry
        return unless authorize_resource_action!("onboarding_provisioning", :retry, @execution)
        return redirect_to(admin_provisioning_execution_path(@execution), alert: "Only failed executions can be retried.") unless @execution.failed?

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
        @execution.reload
        redirect_to admin_provisioning_execution_path(@execution), notice: "Provisioning retried."
      rescue StandardError => e
        redirect_to admin_provisioning_execution_path(@execution), alert: e.message
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
