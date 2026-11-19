# frozen_string_literal: true

module RecordingStudioOnboarding
  class SetupCheck < ActiveRecord::Base
    self.table_name = "recording_studio_onboarding_setup_checks"

    belongs_to :actor, polymorphic: true
    belongs_to :scope, polymorphic: true

    validates :checklist_key, :checked_at, presence: true
  end
end
