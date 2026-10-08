# frozen_string_literal: true

# Soft-registers when RecordingStudioAdmin is present. Require this file only after
# RecordingStudioAdmin is loaded (see Engine to_prepare).

module RecordingStudioOnboarding
  module Admin # rubocop:disable Metrics/ModuleLength
    module_function

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

    def engine_mount_path
      "/onboarding"
    end

    def engine_helpers
      RecordingStudioOnboarding::Engine.routes.url_helpers
    end

    def admin_preview_path(flow_key, step_key)
      engine_helpers.admin_preview_path(flow_key, step_key, script_name: engine_mount_path)
    end

    def admin_run_path(run)
      engine_helpers.admin_run_path(run, script_name: engine_mount_path)
    end

    def admin_reset_run_path(run)
      engine_helpers.reset_admin_run_path(run, script_name: engine_mount_path)
    end

    def admin_restart_run_path(run)
      engine_helpers.restart_admin_run_path(run, script_name: engine_mount_path)
    end

    def admin_provisioning_path(execution)
      engine_helpers.admin_provisioning_execution_path(execution, script_name: engine_mount_path)
    end

    def admin_retry_provisioning_path(execution)
      engine_helpers.retry_admin_provisioning_execution_path(execution, script_name: engine_mount_path)
    end

    def flow_rows # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      counts = FlowRun.group(:flow_key, :status).count
      RecordingStudioOnboarding.configuration.flows.values.map do |definition|
        key = definition.key.to_s
        FlowRow.new(
          key: key,
          scope: definition.scope.to_s,
          step_count: definition.steps.size,
          version: definition.version,
          dismissible: definition.dismissible,
          pending_runs: counts[[key, "pending"]] || 0,
          in_progress_runs: counts[[key, "in_progress"]] || 0,
          completed_runs: counts[[key, "completed"]] || 0,
          dismissed_runs: counts[[key, "dismissed"]] || 0
        )
      end
    end

    def preview_rows
      RecordingStudioOnboarding.configuration.flows.values.flat_map do |definition|
        definition.steps.map do |step|
          PreviewRow.new(
            id: "#{definition.key}-#{step.key}",
            flow_key: definition.key.to_s,
            step_key: step.key.to_s,
            component: step.component.to_s
          )
        end
      end
    end

    def default_flow_key
      RecordingStudioOnboarding.configuration.flows.keys.first&.to_s
    end

    def flow_key_from(context)
      raw = context.params[:flow_key].presence || context.params["flow_key"].presence
      raw.presence || default_flow_key
    end

    def date_bounds_from(context) # rubocop:disable Metrics/MethodLength
      definition = RecordingStudioAdmin::Definitions::FilterDefinition.new(
        :date_range,
        :date_range,
        { field: :started_at, default: :last_30_days }
      )
      range = definition.normalize(context.params)
      return [nil, nil] unless range

      [
        range.start_date&.beginning_of_day,
        range.end_date&.end_of_day
      ]
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

    OpenRunsWidget = RecordingStudioAdmin::Widget.new("onboarding.open_runs") do
      type :number
      title "Open runs"
      info "Pending or in-progress onboarding runs."
      value { FlowRun.open_runs.count }
      hide_change
      hide_period
      blast_radius :site
      link_to { |context| context.admin_screen_path("onboarding_runs") }
    end

    CompletionRateWidget = RecordingStudioAdmin::Widget.new("onboarding.completion_rate") do
      type :number
      title "Completion rate"
      info "Completed runs as a percentage of all runs."
      value do
        total = FlowRun.count
        next 0 if total.zero?

        ((FlowRun.where(status: "completed").count.to_f / total) * 100).round(1)
      end
      hide_change
      hide_period
      blast_radius :site
      link_to { |context| context.admin_screen_path("onboarding_funnel") }
    end

    FailedProvisionsWidget = RecordingStudioAdmin::Widget.new("onboarding.failed_provisions") do
      type :number
      title "Failed provisions"
      info "Provisioning executions that need a retry."
      value { ProvisioningExecution.failed.count }
      hide_change
      hide_period
      blast_radius :site
      link_to { |context| context.admin_screen_path("onboarding_provisioning") }
    end

    class OnboardingSection < RecordingStudioAdmin::Section
      key "onboarding"
      title "Onboarding"
      subtitle "Flows, card previews, runs, funnel, and provisioning"
      blast_radius :site

      widget "onboarding.open_runs"
      widget "onboarding.completion_rate"
      widget "onboarding.failed_provisions"

      link :flows, text: "Flows", url: ->(context) { context.admin_screen_path("onboarding_flows") }
      link :previews, text: "Card previews", url: ->(context) { context.admin_screen_path("onboarding_previews") }
      link :runs, text: "Runs", url: ->(context) { context.admin_screen_path("onboarding_runs") }
      link :funnel, text: "Drop-off funnel", url: ->(context) { context.admin_screen_path("onboarding_funnel") }
      link :provisioning,
           text: "Provisioning",
           url: ->(context) { context.admin_screen_path("onboarding_provisioning") }
    end

    class FlowsScreen < RecordingStudioAdmin::Screen
      key "onboarding_flows"
      title "Onboarding flows"
      subtitle "Registered flows and run counts by status"
      blast_radius :site

      query { |_context| RecordingStudioOnboarding::Admin.flow_rows }

      summary do
        label "Registered flows"
        hide_change
        hide_period
      end

      table do
        column :key, title: "Flow"
        column :scope
        column :step_count, title: "Steps"
        column :version
        column :dismissible, title: "Dismissible"
        column :pending_runs, title: "Pending"
        column :in_progress_runs, title: "In progress"
        column :completed_runs, title: "Completed"
        column :dismissed_runs, title: "Dismissed"
        paginate per_page: 50
      end
    end

    class PreviewsScreen < RecordingStudioAdmin::Screen
      key "onboarding_previews"
      title "Card previews"
      subtitle "Render any step in the card shell without writing runs"
      blast_radius :site

      query { |_context| RecordingStudioOnboarding::Admin.preview_rows }

      table do
        column :flow_key, title: "Flow"
        column :step_key, title: "Step"
        column :component
        action :preview,
               text: "Preview",
               url: lambda { |row, _context|
                 RecordingStudioOnboarding::Admin.admin_preview_path(row.flow_key, row.step_key)
               }
        paginate per_page: 50
      end
    end

    class RunsScreen < RecordingStudioAdmin::Screen
      key "onboarding_runs"
      title "Flow runs"
      subtitle "Filter and inspect onboarding runs"
      blast_radius :site

      query { |_context| FlowRun.order(started_at: :desc) }

      filter :date_range, field: :started_at, default: :last_30_days
      filter :flow_key,
             options: -> { RecordingStudioOnboarding.configuration.flows.keys.map(&:to_s) },
             searchable: true
      filter :status, options: -> { FlowRun::STATUSES }, searchable: true
      filter :scope_type,
             options: -> { FlowRun.distinct.order(:scope_type).pluck(:scope_type) },
             searchable: true
      filter_presentation :modal, inline_count: 2

      summary do
        label "Runs"
        change_good_when :up
      end

      table do
        column :id, title: "UUID", value: ->(row, _ctx) { row.id.to_s }
        column :flow_key, title: "Flow"
        column :status
        column :scope_type, title: "Scope"
        column :current_step_key, title: "Step"
        column :started_at
        column :completed_at
        action :view,
               text: "View",
               url: ->(row, _ctx) { RecordingStudioOnboarding::Admin.admin_run_path(row) }
        action :reset,
               text: "Reset",
               method: :post,
               confirm: "Reset this run to the first step?",
               url: ->(row, _ctx) { RecordingStudioOnboarding::Admin.admin_reset_run_path(row) }
        action :restart,
               text: "Restart",
               method: :post,
               confirm: "Dismiss this run and start a new one?",
               url: ->(row, _ctx) { RecordingStudioOnboarding::Admin.admin_restart_run_path(row) }
        paginate per_page: 25
      end
    end

    class FunnelScreen < RecordingStudioAdmin::Screen
      key "onboarding_funnel"
      title "Drop-off funnel"
      subtitle "Step reach, continuation, dismissals, and median time"
      blast_radius :site

      # Array rows: date/flow filters are UI-only (no AR where). Query reads params.
      query do |context|
        RecordingStudioOnboarding::Admin.funnel_for(context).steps.map do |step|
          FunnelRow.new(
            step_key: step.step_key,
            reached: step.reached,
            continued_pct: step.continued_pct,
            dismissals: step.dismissals,
            median_seconds: step.median_seconds
          )
        end
      end

      filter :date_range, field: :started_at, default: :last_30_days
      filter :flow_key,
             options: -> { RecordingStudioOnboarding.configuration.flows.keys.map(&:to_s) }

      summary do
        label "Completion rate %"
        value { |context| RecordingStudioOnboarding::Admin.funnel_for(context).completion_rate }
        hide_change
        hide_period
      end

      chart do
        title "Reached per step"
        type :bar
        series do |context|
          rows = Array(context.query_result&.relation)
          [
            {
              name: "Reached",
              data: rows.map { |row| { x: row.step_key, y: row.reached } }
            }
          ]
        end
      end

      table do
        column :step_key, title: "Step"
        column :reached
        column :continued_pct, title: "Continued %"
        column :dismissals
        column :median_seconds, title: "Median seconds"
        paginate per_page: 50
      end
    end

    class ProvisioningScreen < RecordingStudioAdmin::Screen
      key "onboarding_provisioning"
      title "Provisioning executions"
      subtitle "Idempotent provisioner runs and failures"
      blast_radius :site

      query { |_context| ProvisioningExecution.order(created_at: :desc) }

      filter :date_range, field: :created_at, default: :last_30_days
      filter :provisioner,
             options: -> { RecordingStudioOnboarding.configuration.provisioners.keys.map(&:to_s) },
             searchable: true
      filter :status, options: -> { ProvisioningExecution::STATUSES }, searchable: true
      filter_presentation :modal, inline_count: 2

      summary do
        label "Executions"
        change_good_when :up
      end

      table do
        column :id, title: "UUID", value: ->(row, _ctx) { row.id.to_s }
        column :provisioner
        column :status
        column :idempotency_key, title: "Idempotency key"
        column :started_at
        column :completed_at
        action :view,
               text: "View",
               url: ->(row, _ctx) { RecordingStudioOnboarding::Admin.admin_provisioning_path(row) }
        action :retry,
               text: "Retry",
               method: :post,
               confirm: "Retry this failed provisioning execution?",
               visible_if: ->(row, _ctx) { row.failed? },
               url: ->(row, _ctx) { RecordingStudioOnboarding::Admin.admin_retry_provisioning_path(row) }
        paginate per_page: 25
      end
    end

    class RunsResource < RecordingStudioAdmin::Resource
      key "onboarding_runs"
      section "onboarding"
      title "Onboarding runs"
      blast_radius :site

      action :reset,
             text: "Reset",
             method: :post,
             required_role: :admin,
             url: ->(row, _ctx) { RecordingStudioOnboarding::Admin.admin_reset_run_path(row) }
      action :restart,
             text: "Restart",
             method: :post,
             required_role: :admin,
             url: ->(row, _ctx) { RecordingStudioOnboarding::Admin.admin_restart_run_path(row) }
    end

    class ProvisioningResource < RecordingStudioAdmin::Resource
      key "onboarding_provisioning"
      section "onboarding"
      title "Provisioning"
      blast_radius :site

      action :retry,
             text: "Retry",
             method: :post,
             required_role: :admin,
             url: ->(row, _ctx) { RecordingStudioOnboarding::Admin.admin_retry_provisioning_path(row) }
    end

    def register! # rubocop:disable Metrics/MethodLength
      return unless defined?(RecordingStudioAdmin)
      return if @registered

      RecordingStudioAdmin.register_widget(OpenRunsWidget)
      RecordingStudioAdmin.register_widget(CompletionRateWidget)
      RecordingStudioAdmin.register_widget(FailedProvisionsWidget)
      RecordingStudioAdmin.register_section(OnboardingSection)
      RecordingStudioAdmin.register_screen(FlowsScreen)
      RecordingStudioAdmin.register_screen(PreviewsScreen)
      RecordingStudioAdmin.register_screen(RunsScreen)
      RecordingStudioAdmin.register_screen(FunnelScreen)
      RecordingStudioAdmin.register_screen(ProvisioningScreen)
      RecordingStudioAdmin.register_resource(RunsResource)
      RecordingStudioAdmin.register_resource(ProvisioningResource)
      @registered = true
    end
  end
end
