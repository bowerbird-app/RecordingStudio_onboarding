# frozen_string_literal: true

module RecordingStudioOnboarding
  module Admin
    FlowRow = Struct.new(
      :key, :scope, :step_count, :version, :dismissible,
      :pending_runs, :in_progress_runs, :completed_runs, :dismissed_runs,
      keyword_init: true
    )

    PreviewRow = Struct.new(:id, :flow_key, :step_key, :component, keyword_init: true)

    FunnelRow = Struct.new(
      :step_key, :reached, :continued_pct, :dismissals, :median_seconds,
      keyword_init: true
    )
  end
end
