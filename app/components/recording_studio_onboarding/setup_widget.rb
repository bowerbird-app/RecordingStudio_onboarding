# frozen_string_literal: true

require "recording_studio_onboarding/setup_widget_registration"

module RecordingStudioOnboarding
  class SetupWidget < ViewComponent::Base
    extend SetupWidgetRegistration

    WIDGET_ID = :onboarding_setup
    Source = Data.define(:status, :title, :link, :subject)

    def initialize(preparation: nil, **)
      super()
      @source = source_from(preparation)
    end

    def render?
      !@source.nil?
    end

    def title
      @source.title
    end

    def subtitle
      @source.status.subtitle
    end

    def status
      @source.status
    end

    def setup_href
      return @source.link if @source.link.present?

      helpers.recording_studio_onboarding.setup_path(status.checklist, **subject_params)
    end

    private

    def source_from(preparation)
      return unless preparation.respond_to?(:state) && preparation.state == :content

      preparation.data
    end

    def subject_params
      subject = @source.subject
      return {} if subject.nil?

      { subject_type: subject.class.name, subject_id: subject.id }
    end
  end
end
