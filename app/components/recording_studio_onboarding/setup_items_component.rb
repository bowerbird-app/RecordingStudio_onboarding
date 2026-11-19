# frozen_string_literal: true

module RecordingStudioOnboarding
  class SetupItemsComponent < ViewComponent::Base
    SURFACE_CLASS = "w-full overflow-hidden rounded-[var(--radius-lg)] border " \
                    "border-[var(--surface-border-color)] bg-[var(--surface-background-color)]"

    attr_reader :status

    def initialize(status:, surface: true)
      super()
      @status = status
      @surface = surface
    end

    def surface?
      @surface
    end

    def list_arguments
      arguments = { divider: true, data: { testid: "setup-remaining" } }
      return arguments unless surface?

      arguments.merge(class: SURFACE_CLASS)
    end

    def row_chevron
      render FlatPack::Shared::IconComponent.new(name: "chevron-right", size: :sm)
    end
  end
end
