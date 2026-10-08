# frozen_string_literal: true

class AddStartedAtIndexToOnboardingFlowRuns < ActiveRecord::Migration[8.1]
  def change
    add_index :recording_studio_onboarding_flow_runs,
              :started_at,
              name: "idx_rso_flow_runs_started_at"
  end
end
