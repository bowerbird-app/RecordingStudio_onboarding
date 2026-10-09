# frozen_string_literal: true

require "recording_studio"
require "view_component"
require "recording_studio_onboarding/version"
require "recording_studio_onboarding/engine"
require "recording_studio_onboarding/configuration"
require "recording_studio_onboarding/gates/terms_and_conditions"
require "recording_studio_onboarding/services/failure_sanitizer"
require "recording_studio_onboarding/services/instrumenter"
require "recording_studio_onboarding/users_registration_integration"

module RecordingStudioOnboarding
  class << self
    def configuration
      @configuration ||= Configuration.new
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

    # Execute a registered provisioner immediately with idempotent tracking.
    def provision(name, **)
      require "recording_studio_onboarding/services/provision"
      Services::Provision.call(name, **)
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

    # In-memory card preview for admin (§23). Writes nothing.
    def preview(flow_key, step_key, context: nil)
      require "recording_studio_onboarding/services/preview_run"
      Services::PreviewRun.call(flow_key: flow_key, step_key: step_key, context: context)
    end

    private

    def require_flow_services!
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
