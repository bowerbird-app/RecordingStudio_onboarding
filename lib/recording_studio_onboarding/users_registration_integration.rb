# frozen_string_literal: true

module RecordingStudioOnboarding
  # Soft integration with RecordingStudio_users registration completion.
  #
  # Requires RecordingStudio_users >= 0.15.0, which emits:
  #   "registration.completed.recording_studio_user"
  # with payload `{ user_id:, method: }` where method is :password, :oauth, or :otp.
  #
  # The older OTP-only event (`otp.registration_completed.recording_studio_user`)
  # is not subscribed here; OTP sign-up is covered by the unified event.
  module UsersRegistrationIntegration
    EVENT = "registration.completed.recording_studio_user"
    LEGACY_OTP_EVENT = "otp.registration_completed.recording_studio_user"
    PROVISIONER = :new_registration
    METHODS = %i[password oauth otp].freeze

    module_function

    def install!
      return if @installed
      return unless defined?(ActiveSupport::Notifications)

      ActiveSupport::Notifications.subscribe(EVENT) do |_name, _start, _finish, _id, payload|
        handle_registration_completed(payload)
      end
      @installed = true
    end

    def handle_registration_completed(payload)
      return unless RecordingStudioOnboarding.configuration.provisioner_registered?(PROVISIONER)
      return unless supported_method?(payload)

      user = resolve_user(payload)
      return if user.nil?

      provision_new_registration(user, payload)
    rescue StandardError => e
      log_provisioning_failure(e)
    end

    def supported_method?(payload)
      method = payload && payload[:method]
      return false if method.nil?

      METHODS.include?(method.to_sym)
    end

    def provision_new_registration(user, payload)
      method = payload[:method].to_sym
      RecordingStudioOnboarding.provision(
        PROVISIONER,
        actor: user,
        subject: user,
        context: { source: EVENT, method: method }
      )
    end

    def log_provisioning_failure(error)
      return unless defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger

      Rails.logger.error(
        "[RecordingStudioOnboarding] Registration provisioning failed: " \
        "#{error.class}: #{error.message}"
      )
    end

    def resolve_user(payload)
      user_id = payload && payload[:user_id]
      return if user_id.blank?

      if defined?(RecordingStudioUser)
        RecordingStudioUser.config.user_class.find_by(id: user_id)
      elsif defined?(User)
        User.find_by(id: user_id)
      end
    end
  end
end
