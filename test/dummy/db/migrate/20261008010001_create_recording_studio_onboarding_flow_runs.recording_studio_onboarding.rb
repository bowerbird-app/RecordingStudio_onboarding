# frozen_string_literal: true

class CreateRecordingStudioOnboardingFlowRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :recording_studio_onboarding_flow_runs, id: :uuid do |t|
      t.string :flow_key, null: false
      t.integer :flow_version, null: false, default: 1
      t.string :scope_type, null: false
      t.uuid :scope_id, null: false
      t.string :initiating_actor_type, null: false
      t.uuid :initiating_actor_id, null: false
      t.string :status, null: false, default: "pending"
      t.string :current_step_key, null: false
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :dismissed_at

      t.timestamps
    end

    add_index :recording_studio_onboarding_flow_runs,
              %i[flow_key scope_type scope_id],
              unique: true,
              where: "status IN ('pending', 'in_progress')",
              name: "idx_rso_flow_runs_open_scope"

    add_index :recording_studio_onboarding_flow_runs,
              %i[flow_key status],
              name: "idx_rso_flow_runs_flow_status"

    add_index :recording_studio_onboarding_flow_runs,
              %i[scope_type scope_id],
              name: "idx_rso_flow_runs_scope"

    add_index :recording_studio_onboarding_flow_runs,
              %i[initiating_actor_type initiating_actor_id],
              name: "idx_rso_flow_runs_actor"

    add_check_constraint :recording_studio_onboarding_flow_runs,
                         "status IN ('pending', 'in_progress', 'completed', 'dismissed')",
                         name: "rso_flow_runs_status_check"
  end
end
