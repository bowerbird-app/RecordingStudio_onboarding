# frozen_string_literal: true

module Dummy
  module Onboarding
    class NameWorkspaceComponent < ViewComponent::Base
      def initialize(run:, step:)
        @run = run
        @step = step
      end

      def call
        content_tag(:div, class: "flex flex-col gap-4", data: {testid: "card-name-workspace"}) do
          safe_join([
            render(FlatPack::PageTitle::Component.new(
                     title: "Workspace setup",
                     subtitle: "Scoped to #{@run.scope.try(:name) || @run.scope_type}.",
                     variant: :h1
                   )),
            content_tag(:p, class: "text-sm leading-6") do
              "This workspace-scoped flow is shared — one open run for the workspace."
            end
          ])
        end
      end
    end
  end
end
