# frozen_string_literal: true

module RecordingStudioOnboarding
  class ProvisioningExecution < ActiveRecord::Base
    self.table_name = "recording_studio_onboarding_provisioning_executions"

    STATUSES = %w[pending running completed failed].freeze

    belongs_to :actor, polymorphic: true
    belongs_to :subject, polymorphic: true, optional: true

    validates :provisioner, :idempotency_key, :status, presence: true
    validates :status, inclusion: { in: STATUSES }
    # Uniqueness of (provisioner, idempotency_key) is enforced by a DB unique
    # index so create_or_find_by! can race safely without RecordInvalid.

    scope :for_provisioner, ->(name) { where(provisioner: name.to_s) }
    scope :completed, -> { where(status: "completed") }
    scope :failed, -> { where(status: "failed") }

    def pending? = status == "pending"
    def running? = status == "running"
    def completed? = status == "completed"
    def failed? = status == "failed"
  end
end
