# frozen_string_literal: true

# Soft-registers when RecordingStudioAdmin is present. Required from Engine
# to_prepare after RecordingStudioAdmin is loaded.

require_relative "admin/rows"
require_relative "admin/paths"
require_relative "admin/widgets"
require_relative "admin/onboarding_section"
require_relative "admin/flows_screen"
require_relative "admin/previews_screen"
require_relative "admin/runs_screen"
require_relative "admin/funnel_screen"
require_relative "admin/provisioning_screen"
require_relative "admin/runs_resource"
require_relative "admin/provisioning_resource"
require_relative "admin/registrar"

module RecordingStudioOnboarding
  module Admin
    module_function

    def flow_rows
      counts = FlowRun.group(:flow_key, :status).count
      RecordingStudioOnboarding.configuration.flows.values.map do |definition|
        flow_row_for(definition, counts)
      end
    end

    def flow_row_for(definition, counts)
      key = definition.key.to_s
      FlowRow.new(flow_row_attributes(definition, key, counts))
    end

    def flow_row_attributes(definition, key, counts)
      {
        key: key, scope: definition.scope.to_s, step_count: definition.steps.size,
        version: definition.version, dismissible: definition.dismissible
      }.merge(flow_row_counts(key, counts))
    end

    def flow_row_counts(key, counts)
      {
        pending_runs: counts[[key, "pending"]] || 0,
        in_progress_runs: counts[[key, "in_progress"]] || 0,
        completed_runs: counts[[key, "completed"]] || 0,
        dismissed_runs: counts[[key, "dismissed"]] || 0
      }
    end

    def preview_rows
      RecordingStudioOnboarding.configuration.flows.values.flat_map do |definition|
        definition.steps.map { |step| preview_row_for(definition, step) }
      end
    end

    def preview_row_for(definition, step)
      PreviewRow.new(
        id: "#{definition.key}-#{step.key}",
        flow_key: definition.key.to_s,
        step_key: step.key.to_s,
        component: step.component.to_s
      )
    end

    def default_flow_key
      RecordingStudioOnboarding.configuration.flows.keys.first&.to_s
    end

    def flow_key_from(context)
      raw = context.params[:flow_key].presence || context.params["flow_key"].presence
      raw.presence || default_flow_key
    end

    def date_bounds_from(context)
      range = date_range_from(context)
      return [nil, nil] unless range

      [range.start_date&.beginning_of_day, range.end_date&.end_of_day]
    end

    def date_range_from(context)
      definition = RecordingStudioAdmin::Definitions::FilterDefinition.new(
        :date_range,
        :date_range,
        { field: :started_at, default: :last_30_days }
      )
      definition.normalize(context.params)
    end

    def funnel_for(context)
      require "recording_studio_onboarding/services/funnel_analytics"
      from_time, to_time = date_bounds_from(context)
      Services::FunnelAnalytics.call(
        flow_key: flow_key_from(context),
        from: from_time,
        to: to_time
      )
    end

    def register!
      Registrar.register!
    end
  end
end
