# frozen_string_literal: true

class CreateRecordingStudioOnboardingSetupChecks < ActiveRecord::Migration[8.1]
  def change
    create_table :recording_studio_onboarding_setup_checks, id: :uuid do |t|
      t.string :checklist_key, null: false
      t.string :actor_type, null: false
      t.uuid :actor_id, null: false
      t.string :scope_type, null: false
      t.uuid :scope_id, null: false
      t.boolean :complete, null: false, default: false
      t.boolean :applicable, null: false, default: true
      t.jsonb :items, null: false, default: []
      t.datetime :checked_at, null: false

      t.timestamps
    end

    add_index :recording_studio_onboarding_setup_checks,
              %i[checklist_key actor_type actor_id scope_type scope_id],
              unique: true,
              name: "idx_rso_setup_checks_identity"

    add_index :recording_studio_onboarding_setup_checks,
              %i[actor_type actor_id],
              name: "idx_rso_setup_checks_actor"
  end
end
