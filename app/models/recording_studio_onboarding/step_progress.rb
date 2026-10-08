# frozen_string_literal: true

module RecordingStudioOnboarding
  class StepProgress < ActiveRecord::Base
    self.table_name = "recording_studio_onboarding_step_progresses"

    STATUSES = %w[pending completed skipped].freeze

    belongs_to :flow_run, class_name: "RecordingStudioOnboarding::FlowRun", inverse_of: :step_progresses
    belongs_to :acted_by, polymorphic: true, optional: true

    validates :step_key, :status, presence: true
    validates :status, inclusion: { in: STATUSES }
    # Uniqueness is enforced by idx_rso_step_progresses_run_step (no AR uniqueness race).

    def pending? = status == "pending"
    def completed? = status == "completed"
    def skipped? = status == "skipped"
  end
end
