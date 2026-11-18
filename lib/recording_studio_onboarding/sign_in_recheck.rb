# frozen_string_literal: true

require "recording_studio_onboarding/services/enqueue_setup_recheck"
require "recording_studio_onboarding/services/evaluate_checklist"

module RecordingStudioOnboarding
  module SignInRecheck
    module_function

    def install!
      return if installed?
      return unless warden_manager

      warden_manager.after_authentication do |user, _auth, _opts|
        enqueue(user)
      end
      @installed = true
    end

    def installed?
      @installed == true
    end

    def reset_for_tests!
      @installed = false
    end

    def warden_manager
      return unless defined?(Warden::Manager)

      Warden::Manager
    end

    def enqueue(user)
      return if user.nil?

      queued = enqueue_user_checklists(user)
      enqueue_saved_rows(user, queued)
    rescue StandardError => e
      log(e)
    end

    def enqueue_user_checklists(user)
      RecordingStudioOnboarding.configuration.checklists.each_with_object([]) do |(key, definition), queued|
        next unless definition.scope == :user
        next unless Services::EvaluateChecklist.new(definition, actor: user, scope: user).applicable?

        Services::EnqueueSetupRecheck.call(key, user, user)
        queued << key.to_s
      end
    end

    def enqueue_saved_rows(user, queued)
      return unless defined?(SetupCheck)

      SetupCheck.where(actor: user).find_each do |row|
        next if row.scope.nil?
        next if queued.include?(row.checklist_key)

        Services::EnqueueSetupRecheck.call(row.checklist_key, user, row.scope)
      end
    end

    def log(error)
      return unless defined?(Rails) && Rails.logger

      Rails.logger.warn(
        "[RecordingStudioOnboarding] Sign-in setup recheck failed: #{Services::FailureSanitizer.call(error)}"
      )
    end
  end
end
