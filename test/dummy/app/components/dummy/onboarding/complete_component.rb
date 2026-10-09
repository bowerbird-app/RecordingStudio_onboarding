# frozen_string_literal: true

module Dummy
  module Onboarding
    # Centred completion card.
    class CompleteComponent < ViewComponent::Base
      def initialize(run:, step:)
        @run = run
        @step = step
      end

      def call
        content_tag(
          :div,
          class: "flex w-full flex-col items-center gap-4 text-center",
          data: {testid: "card-complete"}
        ) do
          safe_join([
            content_tag(:p, "✓", class: "text-4xl", "aria-hidden": true),
            render(FlatPack::PageTitle::Component.new(
                     title: "You’re set",
                     subtitle: "Account setup is ready to finish.",
                     variant: :h1
                   )),
            content_tag(:p, class: "text-sm leading-6") do
              "Continue completes the flow and sends you to the host destination."
            end
          ])
        end
      end
    end
  end
end
