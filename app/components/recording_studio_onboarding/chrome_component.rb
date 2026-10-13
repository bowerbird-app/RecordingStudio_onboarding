# frozen_string_literal: true

module RecordingStudioOnboarding
  # Permanent onboarding chrome: Back (top-left, chevron-left + label) and Skip
  # (top-right) as plain text links. Exit is not part of the chrome.
  class ChromeComponent < ViewComponent::Base
    include EngineRouting

    def initialize(run:, preview: false)
      super()
      @run = run
      @preview = preview || (run.respond_to?(:preview?) && run.preview?)
    end

    def render?
      show_back? || show_skip?
    end

    def call
      content_tag(
        :div,
        class: "flex w-full items-center justify-between gap-4",
        data: { testid: "onboarding-chrome" }
      ) { safe_join([back_link, skip_link]) }
    end

    private

    def show_back?
      !first_step?
    end

    def show_skip?
      skippable?
    end

    def first_step?
      keys = @run.definition&.step_keys || []
      keys.first == @run.current_step_key.to_sym
    end

    def skippable?
      step = @run.current_step
      step.nil? || step.skippable?
    end

    def back_link
      return empty_slot unless show_back?

      text_control(action: :back, testid: "control-back", align: :start) { back_label }
    end

    def skip_link
      return empty_slot unless show_skip?

      text_control(action: :skip, testid: "control-skip", align: :end) { "Skip" }
    end

    def back_label
      safe_join(
        [
          render(FlatPack::Shared::IconComponent.new(name: "chevron-left", size: :sm)),
          "Back"
        ]
      )
    end

    def empty_slot
      content_tag(:span, "", class: "min-w-0 flex-1", "aria-hidden": "true")
    end

    def text_control(action:, testid:, align:, &label)
      wrapper = align == :end ? "ms-auto" : "me-auto"
      return preview_text(testid, wrapper, &label) if @preview

      helpers.form_with(
        url: engine_path("#{action}_run_path"),
        method: :post,
        class: "inline-flex #{wrapper}",
        data: { testid: testid, turbo_frame: "_top" }
      ) { text_control_fields(&label) }
    end

    def text_control_fields(&label)
      safe_join(
        [
          helpers.hidden_field_tag(:from, @run.current_step_key),
          helpers.button_tag(type: "submit", class: text_link_classes, &label)
        ]
      )
    end

    def preview_text(testid, wrapper, &label)
      content_tag(:div, class: "inline-flex #{wrapper}", data: { testid: testid, preview: true }) do
        content_tag(:span, class: text_link_classes, &label)
      end
    end

    def text_link_classes
      "inline-flex items-center gap-1 border-0 bg-transparent p-0 text-sm font-medium " \
        "text-[var(--surface-content-color)] underline-offset-4 " \
        "hover:underline focus-visible:underline " \
        "focus-visible:outline-none cursor-pointer"
    end
  end
end
