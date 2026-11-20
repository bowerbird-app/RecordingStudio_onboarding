# frozen_string_literal: true

require "recording_studio"
require "view_component"
require "recording_studio_onboarding/version"
require "recording_studio_onboarding/provision_failed"
require "recording_studio_onboarding/engine"
require "recording_studio_onboarding/configuration"
require "recording_studio_onboarding/gates/terms_and_conditions"
require "recording_studio_onboarding/services/failure_sanitizer"
require "recording_studio_onboarding/services/instrumenter"
require "recording_studio_onboarding/users_registration_integration"
require "recording_studio_onboarding/sign_in_recheck"

module RecordingStudioOnboarding
  # Raised when start or provision is called without Accessible access on the
  # workspace / subject / root. User-scoped flows still match actor identity.
  class Unauthorized < StandardError; end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    # Replace configuration (and registration install state) between tests.
    def reset_for_tests!(configuration: Configuration.new)
      @configuration = configuration
      UsersRegistrationIntegration.reset_for_tests!
      configuration
    end

    def configure
      yield(configuration) if block_given?
      configuration
    end

    # First blocking gate redirect before user-facing onboarding, or nil.
    # Does not affect provisioning. Gates receive controller, actor, return_path.
    def before_onboarding_redirect_to(controller, actor:, return_path: nil)
      configuration.before_onboarding_gates.each do |gate|
        path = gate.call(controller: controller, actor: actor, return_path: return_path)
        return path if path.present?
      end
      nil
    end

    # Execute a registered provisioner with idempotent tracking.
    # The default finishes the execution when the handler returns. With
    # config.provision_async, a successful handler leaves it pending.
    def provision(name, **)
      require "recording_studio_onboarding/services/provision"
      Services::Provision.call(name, **)
    end

    # Mark an async provisioning execution completed. Idempotent when it
    # already completed. Accepts the execution or its id.
    def complete_provisioning!(execution_or_id)
      require "recording_studio_onboarding/services/finish_provisioning"
      Services::FinishProvisioning.complete!(execution_or_id)
    end

    # Mark an async provisioning execution failed and store the error.
    # Raises when the execution already completed.
    def fail_provisioning!(execution_or_id, error:)
      require "recording_studio_onboarding/services/finish_provisioning"
      Services::FinishProvisioning.fail!(execution_or_id, error: error)
    end

    # Start (or resume) a registered flow. Never redirects or renders UI.
    def start(name, actor:, subject: nil)
      require_flow_services!
      Services::StartFlow.call(name, actor: actor, subject: subject)
    end

    # Open run for the flow+scope, or nil.
    def active_run(name, actor:, subject: nil)
      require_flow_services!
      Services::ActiveRunQuery.call(name, actor: actor, subject: subject)
    end

    def advance(run, from:, actor:)
      require_flow_services!
      Services::TransitionRun.call(run, action: :advance, from: from, actor: actor)
    end

    def back(run, from:, actor:)
      require_flow_services!
      Services::TransitionRun.call(run, action: :back, from: from, actor: actor)
    end

    def skip(run, from:, actor:)
      require_flow_services!
      Services::TransitionRun.call(run, action: :skip, from: from, actor: actor)
    end

    def dismiss(run, actor:)
      require_flow_services!
      Services::TransitionRun.call(run, action: :dismiss, actor: actor)
    end

    def reset(run, actor:)
      require_flow_services!
      Services::ResetRun.call(run, actor: actor)
    end

    def restart(run, actor:)
      require_flow_services!
      Services::RestartRun.call(run, actor: actor)
    end

    def mark_viewed(run, actor: nil)
      require_flow_services!
      Services::MarkStepViewed.call(run, actor: actor)
    end

    # Saved checklist state for a host. The first call computes and saves.
    # Later calls return that row and enqueue a recheck when it is stale.
    # `title`, `subtitle`, and `to_h` are the host surface. Item links are
    # strings resolved on the compute. Onboarding does not know about MCP.
    def setup_status(name, actor:, subject: nil)
      require "recording_studio_onboarding/services/read_setup_status"
      Services::ReadSetupStatus.call(name, actor: actor, subject: subject)
    end

    # In-memory card preview for admin (§23). Writes nothing.
    def preview(flow_key, step_key, context: nil)
      require "recording_studio_onboarding/services/preview_run"
      Services::PreviewRun.call(flow_key: flow_key, step_key: step_key, context: context)
    end

    private

    def require_flow_services!
      require "recording_studio_onboarding/services/accessible_authorization"
      require "recording_studio_onboarding/services/scope_resolver"
      require "recording_studio_onboarding/services/reconcile_run"
      require "recording_studio_onboarding/services/start_flow"
      require "recording_studio_onboarding/services/active_run_query"
      require "recording_studio_onboarding/services/transition_run"
      require "recording_studio_onboarding/services/reset_run"
      require "recording_studio_onboarding/services/restart_run"
      require "recording_studio_onboarding/services/mark_step_viewed"
    end
  end
end
