# frozen_string_literal: true

module RecordingStudioOnboarding
  module Admin
    class BaseController < ApplicationController
      include RecordingStudioAdmin::AdminActionAuditing if defined?(RecordingStudioAdmin::AdminActionAuditing)

      before_action :require_admin_actor!
      before_action :authorize_admin_actor!

      layout "recording_studio_onboarding/admin"

      helper_method :recording_studio_admin_context

      private

      def require_admin_actor!
        return if current_onboarding_actor.present?

        head :unauthorized
      end

      def authorize_admin_actor!
        return if performed?
        return head :forbidden unless defined?(RecordingStudioAdmin)

        RecordingStudioAdmin::Authorization.authorize!(
          recording_studio_admin_context,
          recording: admin_access_recording
        )
      rescue RecordingStudioAdmin::AuthorizationFailed
        head :forbidden
      end

      def recording_studio_admin_context
        @recording_studio_admin_context ||= RecordingStudioAdmin::Context.new(
          params: params.to_unsafe_h,
          current_actor: current_onboarding_actor,
          controller: self,
          routes: self,
          view_context: view_context
        )
      end

      def admin_access_recording
        resolver = RecordingStudioAdmin.configuration.access_recording_resolver
        resolver&.call(recording_studio_admin_context)
      end

      def authorize_resource_action!(resource_key, action_key, record)
        RecordingStudioAdmin.authorize_resource!(
          key: resource_key,
          action: action_key,
          context: recording_studio_admin_context,
          record: record
        )
      rescue RecordingStudioAdmin::AuthorizationFailed, RecordingStudioAdmin::DefinitionNotFound
        head :forbidden
        nil
      end
    end
  end
end
