# frozen_string_literal: true

module RecordingStudioOnboarding
  module Admin
    unless const_defined?(:SUPPORT_FILES, false)
      SUPPORT_FILES = %w[
        rows
        paths
        widgets
        onboarding_section
        flows_screen
        previews_screen
        runs_screen
        funnel_screen
        provisioning_screen
        runs_resource
        provisioning_resource
        registrar
      ].freeze
    end

    # Struct and widget assignments warn if reloaded while the constant remains.
    # Classes and modules reopen quietly. Zeitwerk can drop Registrar and leave
    # the assignments in place.
    unless const_defined?(:OWNED_ASSIGNMENTS, false)
      OWNED_ASSIGNMENTS = %i[
        FlowRow
        PreviewRow
        FunnelRow
        OpenRunsWidget
        CompletionRateWidget
        FailedProvisionsWidget
      ].freeze
    end

    def self.load_support_files!
      return if const_defined?(:Registrar, false)

      OWNED_ASSIGNMENTS.each do |name|
        remove_const(name) if const_defined?(name, false)
      end

      SUPPORT_FILES.each do |name|
        load File.expand_path("#{name}.rb", __dir__)
      end
    end
  end
end
