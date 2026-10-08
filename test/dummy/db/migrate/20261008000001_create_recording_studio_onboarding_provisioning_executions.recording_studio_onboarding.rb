# frozen_string_literal: true

class CreateRecordingStudioOnboardingProvisioningExecutions < ActiveRecord::Migration[8.1]
  def change
    create_table :recording_studio_onboarding_provisioning_executions, id: :uuid do |t|
      t.string :provisioner, null: false
      t.string :idempotency_key, null: false
      t.string :actor_type, null: false
      t.uuid :actor_id, null: false
      t.string :subject_type
      t.uuid :subject_id
      t.string :status, null: false, default: "pending"
      t.datetime :started_at
      t.datetime :completed_at
      t.text :failure_details

      t.timestamps
    end

    add_index :recording_studio_onboarding_provisioning_executions,
              %i[provisioner idempotency_key],
              unique: true,
              name: "idx_rso_provisioning_executions_idempotency"

    add_index :recording_studio_onboarding_provisioning_executions,
              %i[actor_type actor_id],
              name: "idx_rso_provisioning_executions_actor"

    add_index :recording_studio_onboarding_provisioning_executions,
              :status,
              name: "idx_rso_provisioning_executions_status"

    add_check_constraint :recording_studio_onboarding_provisioning_executions,
                         "status IN ('pending', 'running', 'completed', 'failed')",
                         name: "rso_provisioning_executions_status_check"
  end
end
