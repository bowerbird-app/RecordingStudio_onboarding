# frozen_string_literal: true

module RecordingStudioOnboarding
  module Admin
    module Paths
      module_function

      def engine_mount_path
        "/onboarding"
      end

      def engine_helpers
        RecordingStudioOnboarding::Engine.routes.url_helpers
      end

      def admin_preview_path(flow_key, step_key)
        engine_helpers.admin_preview_path(flow_key, step_key, script_name: engine_mount_path)
      end

      def admin_run_path(run)
        engine_helpers.admin_run_path(run, script_name: engine_mount_path)
      end

      def admin_reset_run_path(run)
        engine_helpers.reset_admin_run_path(run, script_name: engine_mount_path)
      end

      def admin_restart_run_path(run)
        engine_helpers.restart_admin_run_path(run, script_name: engine_mount_path)
      end

      def admin_provisioning_path(execution)
        engine_helpers.admin_provisioning_execution_path(execution, script_name: engine_mount_path)
      end

      def admin_retry_provisioning_path(execution)
        engine_helpers.retry_admin_provisioning_execution_path(execution, script_name: engine_mount_path)
      end
    end
  end
end
