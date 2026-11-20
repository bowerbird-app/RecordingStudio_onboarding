# frozen_string_literal: true

# Password sign-up sends its confirmation code through Notifications.
# Deliver in the request so the code is on the challenge before the response.
RecordingStudioNotifications.configure do |config|
  config.deliver_later = false
  config.actor_resolver = -> { Current.actor }
end

RecordingStudioNotificationsEmail.configure do |config|
  config.from = "notifications@example.test"
end
