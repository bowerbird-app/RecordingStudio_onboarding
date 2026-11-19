# frozen_string_literal: true

require "recording_studio_onboarding/setup_record"

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

    def to_h(only: nil, except: nil, url_options: nil)
      SetupRecord.build(self, only: only, except: except, url_options: url_options)
    end

    def as_json(options = nil, only: nil, except: nil, url_options: nil)
      hash = options.is_a?(Hash) ? options : {}
      to_h(
        only: json_option(only, hash, :only),
        except: json_option(except, hash, :except),
        url_options: json_option(url_options, hash, :url_options)
      )
    end

    private

    def checklist_definition
      RecordingStudioOnboarding.configuration.checklist_for(checklist)
    end

    def json_option(keyword, hash, name)
      return keyword unless keyword.nil?

      hash[name] || hash[name.to_s]
    end
  end
end
