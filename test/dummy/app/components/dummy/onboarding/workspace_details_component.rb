# frozen_string_literal: true

module Dummy
  module Onboarding
    # Form card — posts to the host controller; gem never persists host data.
    class WorkspaceDetailsComponent < ViewComponent::Base
      def initialize(run:, step:)
        @run = run
        @step = step
      end

      def call
        content_tag(:div, class: "flex w-full flex-col gap-4", data: {testid: "card-workspace-details"}) do
          safe_join([
            render(FlatPack::PageTitle::Component.new(
                     title: "Name your workspace",
                     subtitle: "Narrow form card posting to the host app.",
                     variant: :h2
                   )),
            error_alert,
            helpers.form_with(
              url: helpers.main_app.onboarding_workspace_details_path,
              method: :post,
              class: "flex flex-col gap-4",
              data: {testid: "workspace-details-form"}
            ) do
              safe_join([
                helpers.hidden_field_tag(:run_id, @run.id),
                helpers.hidden_field_tag(:from, @step.key),
                render(FlatPack::TextInput::Component.new(
                         name: "workspace[name]",
                         label: "Workspace name",
                         value: helpers.params.dig(:workspace, :name),
                         error: Array(helpers.flash[:form_error]).first,
                         required: true
                       )),
                render(FlatPack::Button::Component.new(
                         text: "Save and continue",
                         style: :primary,
                         type: "submit"
                       ))
              ])
            end
          ])
        end
      end

      private

      def error_alert
        message = helpers.flash[:form_error]
        return unless message.present?

        render FlatPack::Alert::Component.new(
          title: "Couldn’t save",
          description: message.to_s,
          style: :danger
        )
      end
    end
  end
end
