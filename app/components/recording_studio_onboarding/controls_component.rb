# frozen_string_literal: true

module RecordingStudioOnboarding
  # Right-aligned footer button. Back and the top Skip live in ChromeComponent.
  # `footer_action` picks Continue (advance) or Skip (the existing skip action).
  class ControlsComponent < ViewComponent::Base
    include EngineRouting

    BOTTOM_CONTROLS = %i[continue].freeze
    POSITIONS = %i[left right full].freeze
    DEFAULT_POSITION = :right

    def initialize(run:, controls: nil, preview: false, button_positions: nil)
      super()
      @run = run
      @preview = preview_mode?(preview, run)
      @controls = resolve_controls(controls, run)
      @button_positions = normalize_positions(button_positions || run.current_step&.button_positions)
    end

    def preview_mode?(preview, run) = preview || (run.respond_to?(:preview?) && run.preview?)

    def resolve_controls(controls, run) = Array(controls || run.current_step&.controls || []).map(&:to_sym)
    private :preview_mode?, :resolve_controls

    def render? = (@run.open? || @preview) && visible_controls.any?

    def call
      content_tag(:div, class: "mt-10 flex w-full flex-col gap-3", data: { testid: "onboarding-controls" }) do
        safe_join([full_region, row_region].compact)
      end
    end

    private

    def normalize_positions(raw)
      Hash(raw).each_with_object({}) do |(key, value), memo|
        position = value.to_sym
        next unless POSITIONS.include?(position)

        memo[key.to_sym] = position
      end
    end

    def visible_controls = BOTTOM_CONTROLS.select { |control| @controls.include?(control) }

    def position_for(control)
      return :right if control == :continue

      @button_positions.fetch(control, DEFAULT_POSITION)
    end

    def full_region
      buttons = controls_for(:full)
      return if buttons.empty?

      content_tag(:div, class: "flex w-full flex-col gap-3") do
        safe_join(buttons.map { |control| render_control(control, full: true) })
      end
    end

    def row_region
      left = controls_for(:left)
      right = controls_for(:right)
      return if left.empty? && right.empty?

      content_tag(:div, class: "flex w-full flex-wrap items-center gap-3") do
        safe_join([control_group(left), control_group(right, align: :end)].compact)
      end
    end

    def controls_for(position) = visible_controls.select { |control| position_for(control) == position }

    def control_group(controls, align: :start)
      return if controls.empty?

      classes = align == :end ? "ms-auto flex flex-wrap items-center gap-3" : "flex flex-wrap items-center gap-3"
      content_tag(:div, class: classes) do
        safe_join(controls.map { |control| render_control(control, full: false) })
      end
    end

    def render_control(control, full:)
      return unless control == :continue

      label, action, testid = footer_button
      control_button(label, action, style: :primary, full: full, testid: testid)
    end

    def footer_button
      if @run.current_step&.footer_skips?
        ["Skip", :skip, "control-skip"]
      else
        ["Continue", :advance, "control-advance"]
      end
    end

    def control_button(label, action, style:, full:, testid:)
      return preview_button(label, style, testid, full) if @preview

      form_button(engine_path("#{action}_run_path"), label, style, testid, full: full)
    end

    def preview_button(label, style, testid, full)
      content_tag(:div, class: full ? "block w-full" : "inline-flex", data: { testid: testid, preview: true }) do
        render flatpack_button(label, style, "button", full)
      end
    end

    def form_button(url, label, style, testid, full:)
      helpers.form_with(
        url: url, method: :post, class: full ? "block w-full" : "inline-flex",
        data: { testid: testid, turbo_frame: "_top" }
      ) { form_button_fields(label, style, full) }
    end

    def form_button_fields(label, style, full)
      safe_join(
        [
          helpers.hidden_field_tag(:from, @run.current_step_key),
          render(flatpack_button(label, style, "submit", full))
        ]
      )
    end

    def flatpack_button(label, style, type, full)
      FlatPack::Button::Component.new(
        text: label, style: style, type: type, size: :md,
        class: (full ? "w-full justify-center" : nil)
      )
    end
  end
end
