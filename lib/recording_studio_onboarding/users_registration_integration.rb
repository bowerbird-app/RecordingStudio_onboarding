# frozen_string_literal: true

module RecordingStudioOnboarding
  # Soft integration with RecordingStudio_users where a real extension point exists.
  #
  # RecordingStudio_users currently instruments only OTP registration completion:
  #   "otp.registration_completed.recording_studio_user"
  #
  # Password registration and OmniAuth new-account creation do not emit a public
  # hook. Hosts must call RecordingStudioOnboarding.provision explicitly for those
  # paths until RecordingStudio_users adds a registration-completed notification.
  module UsersRegistrationIntegration
    OTP_EVENT = "otp.registration_completed.recording_studio_user"
    PROVISIONER = :new_registration

    module_function

    def install!
      return if @installed
      return unless defined?(ActiveSupport::Notifications)

      ActiveSupport::Notifications.subscribe(OTP_EVENT) do |_name, _start, _finish, _id, payload|
        handle_otp_registration_completed(payload)
      end
      @installed = true
    end

    def handle_otp_registration_completed(payload)
      return unless RecordingStudioOnboarding.configuration.provisioner_registered?(PROVISIONER)

      user = resolve_user(payload)
      return if user.nil?

      RecordingStudioOnboarding.provision(
        PROVISIONER,
        actor: user,
        subject: user,
        context: { source: "otp.registration_completed.recording_studio_user" }
      )
    rescue StandardError => error
      Rails.logger.error(
        "[RecordingStudioOnboarding] OTP registration provisioning failed: #{error.class}: #{error.message}"
      ) if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
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
