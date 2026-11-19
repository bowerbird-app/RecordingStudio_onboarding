# frozen_string_literal: true

require "recording_studio_onboarding/services/accessible_authorization"
require "recording_studio_onboarding/services/refresh_setup_status"
require "recording_studio_onboarding/services/scope_resolver"

module RecordingStudioOnboarding
  class SetupController < ApplicationController
    before_action :require_actor!
    before_action :use_document_title_layout

    def show
      definition = RecordingStudioOnboarding.configuration.checklist_for(params[:checklist])
      return render_not_found if definition.nil?

      subject = subject_for(definition)
      return render_not_found unless allowed?(definition, subject)

      @status = Services::RefreshSetupStatus.call(definition.key, actor: current_onboarding_actor, subject: subject)
    rescue ArgumentError
      render_not_found
    end

    private

    def require_actor!
      render_not_found if current_onboarding_actor.nil?
    end

    def use_document_title_layout
      return if host_replaced_default_layout?

      prepend_view_path RecordingStudioOnboarding::Engine.root.join("app/setup_layout")
    end

    def host_replaced_default_layout?
      found = lookup_context.find_all("default_layout", ["recording_studio/shared"], true).first
      return false if found.nil?

      stock = RecordingStudio::Engine.root.join("app/views/recording_studio/shared/_default_layout.html.erb")
      Pathname(found.identifier).cleanpath != stock.cleanpath
    end

    def subject_for(definition)
      return if definition.scope == :user

      find_subject
    end

    def find_subject
      klass = subject_class
      return if klass.nil? || !(klass < ActiveRecord::Base)

      klass.find_by(id: params[:subject_id])
    end

    def subject_class
      name = params[:subject_type].to_s
      return unless name.match?(/\A[A-Z][A-Za-z0-9:]+\z/)

      name.safe_constantize
    end

    def allowed?(definition, subject)
      scope = Services::ScopeResolver.call(definition, actor: current_onboarding_actor, subject: subject)
      Services::AccessibleAuthorization.allowed_for_scope?(
        definition: definition,
        scope: scope,
        actor: current_onboarding_actor
      )
    end

    def render_not_found
      head :not_found
    end
  end
end
