# frozen_string_literal: true

require "recording_studio_onboarding/setup_status"

module RecordingStudioOnboarding
  module SetupSnapshot
    module_function

    def dump(status)
      (status.done + status.remaining).map { |item| dump_item(item) }
    end

    def dump_item(item)
      { "key" => item.key.to_s, "next_step" => item.next_step, "link" => item.link, "done" => item.done }
    end

    def load(definition, row)
      done, remaining = Array(row.items).map { |entry| item_from(entry) }.partition(&:done)
      SetupStatus.new(
        checklist: definition.key,
        applicable: row.applicable,
        complete: row.complete,
        next_item: remaining.first,
        done: done,
        remaining: remaining,
        checked_at: row.checked_at
      )
    end

    def item_from(entry)
      fields = entry.to_h.transform_keys(&:to_s)
      SetupItem.new(
        key: fields["key"].to_sym,
        next_step: fields["next_step"].to_s,
        link: fields["link"],
        done: fields["done"] == true
      )
    end
  end
end
