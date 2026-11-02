# frozen_string_literal: true

module RecordingStudioOnboarding
  module Admin
    module Registrar
      module_function

      def register!
        return unless defined?(RecordingStudioAdmin)

        register_widgets!
        register_screens!
        register_resources!
      end

      def register_widgets!
        RecordingStudioAdmin.register_widget(OpenRunsWidget)
        RecordingStudioAdmin.register_widget(CompletionRateWidget)
        RecordingStudioAdmin.register_widget(FailedProvisionsWidget)
      end

      def register_screens!
        RecordingStudioAdmin.register_section(OnboardingSection)
        RecordingStudioAdmin.register_screen(FlowsScreen)
        RecordingStudioAdmin.register_screen(PreviewsScreen)
        RecordingStudioAdmin.register_screen(RunsScreen)
        RecordingStudioAdmin.register_screen(FunnelScreen)
        RecordingStudioAdmin.register_screen(ProvisioningScreen)
      end

      def register_resources!
        RecordingStudioAdmin.register_resource(RunsResource)
        RecordingStudioAdmin.register_resource(ProvisioningResource)
      end
    end
  end
end
