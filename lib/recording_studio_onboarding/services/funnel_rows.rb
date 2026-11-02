# frozen_string_literal: true

module RecordingStudioOnboarding
  module Services
    FunnelStepRow = Struct.new(
      :step_key,
      :reached,
      :continued_pct,
      :dismissals,
      :median_seconds,
      keyword_init: true
    )

    FunnelSummary = Struct.new(
      :flow_key,
      :total_runs,
      :completed,
      :dismissed,
      :completion_rate,
      :dismissal_rate,
      :steps,
      keyword_init: true
    )
  end
end
