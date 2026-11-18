# frozen_string_literal: true

module RecordingStudioOnboarding
  SetupItem = Data.define(:key, :next_step, :link, :done) do
    def done? = done
  end

  # Result of `RecordingStudioOnboarding.setup_status`.
  SetupStatus = Data.define(
    :checklist, :applicable, :complete, :next_item, :done, :remaining, :checked_at
  ) do
    def complete? = complete
    def applicable? = applicable
  end
end
