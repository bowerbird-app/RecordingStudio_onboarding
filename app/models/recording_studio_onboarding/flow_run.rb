# frozen_string_literal: true

module RecordingStudioOnboarding
  class FlowRun < ActiveRecord::Base
    self.table_name = "recording_studio_onboarding_flow_runs"

    OPEN_STATUSES = %w[pending in_progress].freeze
    STATUSES = (OPEN_STATUSES + %w[completed dismissed]).freeze

    belongs_to :scope, polymorphic: true
    belongs_to :initiating_actor, polymorphic: true
    has_many :step_progresses,
             class_name: "RecordingStudioOnboarding::StepProgress",
             dependent: :destroy,
             inverse_of: :flow_run

    validates :flow_key, :flow_version, :status, :current_step_key, presence: true
    validates :status, inclusion: { in: STATUSES }

    scope :open_runs, -> { where(status: OPEN_STATUSES) }
    scope :for_flow, ->(key) { where(flow_key: key.to_s) }

    def open?
      OPEN_STATUSES.include?(status)
    end

    def pending? = status == "pending"
    def in_progress? = status == "in_progress"
    def completed? = status == "completed"
    def dismissed? = status == "dismissed"

    def definition
      RecordingStudioOnboarding.configuration.flow_for(flow_key)
    end

    def current_step
      definition&.step_for(current_step_key)
    end

    def progress_ratio
      visible = definition&.visible_steps || []
      return 0.0 if visible.empty?

      completed_keys = step_progresses.where(status: %w[completed skipped]).pluck(:step_key).map(&:to_sym)
      done = visible.count { |step| completed_keys.include?(step.key) }
      done.to_f / visible.size
    end
  end
end
