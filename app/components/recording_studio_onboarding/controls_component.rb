# frozen_string_literal: true

module RecordingStudioOnboarding
  # Shared Back / Continue / Skip / Exit controls. State transitions hit engine routes.
  # Plain form submits (no Stimulus required).
  class ControlsComponent < ViewComponent::Base
    CONTROL_ORDER = %i[back continue skip exit].freeze

    def initialize(run:, controls: nil)
      super()
      @run = run
      @controls = Array(controls || run.current_step&.controls || []).map(&:to_sym)
    end

    def render?
      @run.open? && visible_controls.any?
    end

    def call
      content_tag(:div, class: "flex flex-wrap items-center gap-3", data: { testid: "onboarding-controls" }) do
        safe_join(visible_controls.map { |control| render_control(control) })
      end
    end

    private

    def visible_controls
      CONTROL_ORDER.select { |control| show?(control) }
    end

    def show?(control)
      return false unless @controls.include?(control)
      return false if control == :skip && !skippable?
      return false if control == :back && first_step?

      true
    end

    def skippable?
      step = @run.current_step
      step.nil? || step.skippable?
    end

    def first_step?
      keys = @run.definition&.step_keys || []
      keys.first == @run.current_step_key.to_sym
    end

    def render_control(control)
      case control
      when :back then transition_form("Back", :back, style: :secondary)
      when :continue then transition_form("Continue", :advance, style: :primary)
      when :skip then transition_form("Skip", :skip, style: :ghost)
      when :exit then exit_form
      end
    end

    def transition_form(label, action, style:)
      form_button(engine_path("#{action}_run_path"), label, style, "control-#{action}", from: true)
    end

    def exit_form
      form_button(engine_path("dismiss_run_path"), "Exit", :ghost, "control-exit", from: false)
    end

    def form_button(url, label, style, testid, from:)
      helpers.form_with(url: url, method: :post, class: "inline-flex",
                        data: { testid: testid, turbo_frame: "_top" }) do
        parts = []
        parts << helpers.hidden_field_tag(:from, @run.current_step_key) if from
        parts << render(FlatPack::Button::Component.new(text: label, style: style, type: "submit", size: :md))
        safe_join(parts)
      end
    end

    # Resolve engine route helpers whether rendered inside the engine or a host page.
    def engine_path(helper_name)
      if helpers.respond_to?(helper_name)
        helpers.public_send(helper_name, @run)
      elsif helpers.respond_to?(:recording_studio_onboarding)
        helpers.recording_studio_onboarding.public_send(helper_name, @run)
      else
        RecordingStudioOnboarding::Engine.routes.url_helpers.public_send(
          helper_name, @run, script_name: "/onboarding"
        )
      end
    end
  end
end
