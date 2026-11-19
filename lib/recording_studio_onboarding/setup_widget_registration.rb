# frozen_string_literal: true

module RecordingStudioOnboarding
  module SetupWidgetRegistration
    def prepare(context, config)
      options = (config || {}).to_h.transform_keys(&:to_sym)
      checklist = options.fetch(:checklist)
      subject = resolve_with_context(options[:subject], context)
      status = checklist_status(context, checklist, subject)
      return dashboard_empty unless show_status?(status, options)

      dashboard_content(source_for(status, options, context, subject))
    rescue RecordingStudioOnboarding::Unauthorized
      dashboard_empty
    end

    def register_dashboard_widget!
      return unless defined?(::RecordingStudioDashboard)
      return if dashboard_widget_registered?

      ::RecordingStudioDashboard.register_widget(SetupWidget::WIDGET_ID, **widget_type)
    end

    private

    def widget_type
      {
        component: SetupWidget, title: "Setup checklist", description: "Remaining setup items",
        default_span: 6, supported_spans: [6, 12],
        options: %i[checklist link subject show_complete], empty: :hide
      }
    end

    def checklist_status(context, checklist, subject)
      raise ArgumentError, "checklist is required" if checklist.blank?

      RecordingStudioOnboarding.setup_status(checklist, actor: actor_from(context), subject: subject)
    end

    def source_for(status, options, context, subject)
      SetupWidget::Source.new(
        status: status,
        link: resolve_with_context(options[:link], context),
        subject: subject
      )
    end

    def show_status?(status, options)
      return false unless status.applicable?
      return true unless status.complete?

      options[:show_complete] == true
    end

    def actor_from(context)
      return if context.nil?
      return context.actor if context.respond_to?(:actor)

      context
    end

    def resolve_with_context(value, context)
      return if value.nil?
      return value.call(context) if value.is_a?(Proc)

      value
    end

    def dashboard_empty
      ::RecordingStudioDashboard::Preparation.empty
    end

    def dashboard_content(source)
      ::RecordingStudioDashboard::Preparation.content(source)
    end

    def dashboard_widget_registered?
      ::RecordingStudioDashboard.registry.widget(SetupWidget::WIDGET_ID)
      true
    rescue KeyError
      false
    end
  end
end
