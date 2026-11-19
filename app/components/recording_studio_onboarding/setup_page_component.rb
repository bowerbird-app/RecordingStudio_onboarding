# frozen_string_literal: true

module RecordingStudioOnboarding
  class SetupPageComponent < ViewComponent::Base
    attr_reader :status

    def initialize(status:, heading: true)
      super()
      @status = status
      @heading = heading
    end

    def heading?
      @heading
    end

    def title
      checklist&.title || ChecklistDefinition::DEFAULT_TITLE
    end

    def subtitle
      checklist&.subtitle_for(status) || ChecklistDefinition.default_subtitle(status)
    end

    def row_chevron
      render FlatPack::Shared::IconComponent.new(name: "chevron-right", size: :sm)
    end

    private

    def checklist
      RecordingStudioOnboarding.configuration.checklist_for(status.checklist)
    end
  end
end
