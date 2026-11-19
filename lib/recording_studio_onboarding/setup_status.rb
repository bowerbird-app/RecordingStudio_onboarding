# frozen_string_literal: true

module RecordingStudioOnboarding
  SetupItem = Data.define(:key, :next_step, :link, :icon, :done) do
    def done? = done

    def to_h
      {
        "key" => key.to_s,
        "next_step" => next_step,
        "icon" => icon.to_s,
        "link" => link
      }
    end

    def as_json(*)
      to_h
    end
  end

  # Result of `RecordingStudioOnboarding.setup_status`.
  SetupStatus = Data.define(
    :checklist, :applicable, :complete, :next_item, :done, :remaining, :checked_at
  ) do
    def complete? = complete
    def applicable? = applicable

    def title
      checklist_definition&.title || ChecklistDefinition::DEFAULT_TITLE
    end

    def subtitle
      return checklist_definition.subtitle_for(self) if checklist_definition

      ChecklistDefinition.default_subtitle(self)
    end

    def to_h
      {
        "checklist" => checklist.to_s,
        "title" => title,
        "subtitle" => subtitle,
        "applicable" => applicable?,
        "complete" => complete?,
        "remaining" => remaining.map(&:to_h),
        "done" => done.map(&:to_h)
      }
    end

    def as_json(*)
      to_h
    end

    private

    def checklist_definition
      RecordingStudioOnboarding.configuration.checklist_for(checklist)
    end
  end
end
