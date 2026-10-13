# frozen_string_literal: true

module RecordingStudioOnboarding
  # Permanent onboarding chrome: "< Back" (top-left) and "Skip" (top-right) as
  # plain text links. Exit is not part of the chrome.
  class ChromeComponent < ViewComponent::Base
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
      ) do
        safe_join([back_link, skip_link])
      end
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

      text_control(
        label: "< Back",
        action: :back,
        testid: "control-back",
        align: :start
      )
    end

    def skip_link
      return empty_slot unless show_skip?

      text_control(
        label: "Skip",
        action: :skip,
        testid: "control-skip",
        align: :end
      )
    end

    def empty_slot
      content_tag(:span, "", class: "min-w-0 flex-1", "aria-hidden": "true")
    end

    def text_control(label:, action:, testid:, align:)
      wrapper = align == :end ? "ms-auto" : "me-auto"
      return preview_text(label, testid, wrapper) if @preview

      helpers.form_with(
        url: engine_path("#{action}_run_path"),
        method: :post,
        class: "inline-flex #{wrapper}",
        data: { testid: testid, turbo_frame: "_top" }
      ) do
        safe_join(
          [
            helpers.hidden_field_tag(:from, @run.current_step_key),
            helpers.button_tag(
              label,
              type: "submit",
              class: text_link_classes
            )
          ]
        )
      end
    end

    def preview_text(label, testid, wrapper)
      content_tag(:div, class: "inline-flex #{wrapper}", data: { testid: testid, preview: true }) do
        content_tag(:span, label, class: text_link_classes)
      end
    end

    def text_link_classes
      "border-0 bg-transparent p-0 text-sm font-medium " \
        "text-[var(--surface-content-color)] underline-offset-4 " \
        "hover:underline focus-visible:underline " \
        "focus-visible:outline-none cursor-pointer"
    end

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
