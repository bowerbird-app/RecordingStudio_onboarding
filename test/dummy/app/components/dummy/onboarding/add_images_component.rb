# frozen_string_literal: true

module Dummy
  module Onboarding
    # Host form step with complete_when auto-advance support.
    class AddImagesComponent < ViewComponent::Base
      def initialize(run:, step:)
        @run = run
        @step = step
      end

      def call
        content_tag(:div, class: "flex flex-col gap-4", data: {testid: "card-add-images"}) do
          safe_join([
            render(FlatPack::PageTitle::Component.new(
                     title: "Add images",
                     subtitle: "Mark the page title with “ready” to auto-complete this step.",
                     variant: :h2
                   )),
            helpers.form_with(
              url: helpers.main_app.onboarding_presskit_images_path,
              method: :post,
              class: "flex flex-col gap-4",
              data: {testid: "presskit-images-form"}
            ) do
              safe_join([
                helpers.hidden_field_tag(:run_id, @run.id),
                helpers.hidden_field_tag(:from, @step.key),
                render(FlatPack::TextInput::Component.new(
                         name: "page[title]",
                         label: "Page title",
                         value: @run.scope.try(:title),
                         required: true
                       )),
                render(FlatPack::Button::Component.new(
                         text: "Save title",
                         style: :primary,
                         type: "submit"
                       ))
              ])
            end
          ])
        end
      end
    end
  end
end
