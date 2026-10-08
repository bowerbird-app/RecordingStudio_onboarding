# frozen_string_literal: true

class CreateRecordingStudioOnboardingStepProgresses < ActiveRecord::Migration[8.1]
  def change
    create_table :recording_studio_onboarding_step_progresses, id: :uuid do |t|
      t.uuid :flow_run_id, null: false
      t.string :step_key, null: false
      t.string :status, null: false, default: "pending"
      t.string :acted_by_type
      t.uuid :acted_by_id
      t.datetime :acted_at
      t.datetime :first_viewed_at

      t.timestamps
    end

    add_index :recording_studio_onboarding_step_progresses,
              %i[flow_run_id step_key],
              unique: true,
              name: "idx_rso_step_progresses_run_step"

    add_index :recording_studio_onboarding_step_progresses,
              :status,
              name: "idx_rso_step_progresses_status"

    add_foreign_key :recording_studio_onboarding_step_progresses,
                    :recording_studio_onboarding_flow_runs,
                    column: :flow_run_id

    add_check_constraint :recording_studio_onboarding_step_progresses,
                         "status IN ('pending', 'completed', 'skipped')",
                         name: "rso_step_progresses_status_check"
  end
end
