# frozen_string_literal: true

require "recording_studio_onboarding/services/refresh_setup_status"

module RecordingStudioOnboarding
  module Admin
    class SetupLookupsController < BaseController
      def show
        @checklist_options = RecordingStudioOnboarding.configuration.checklists.keys.map { |key| [key.to_s, key.to_s] }
        @status = lookup_status
      end

      private

      def lookup_status
        return if params[:email].blank? || params[:checklist].blank?

        actor, definition = lookup_pair
        @message = lookup_message(actor, definition)
        return if @message

        Services::RefreshSetupStatus.call(definition.key, actor: actor)
      end

      def lookup_pair
        actor = find_actor(params[:email].to_s.strip)
        definition = RecordingStudioOnboarding.configuration.checklist_for(params[:checklist])
        [actor, definition]
      end

      def lookup_message(actor, definition)
        return "No account uses that email." if actor.nil?
        return "That checklist is not registered." if definition.nil?
        return if definition.scope == :user

        "This checklist follows a workspace. Open Your setup from that workspace."
      end

      def find_actor(email)
        return unless defined?(RecordingStudioUser)

        RecordingStudioUser.config.user_class.find_by(email: email)
      end
    end
  end
end
