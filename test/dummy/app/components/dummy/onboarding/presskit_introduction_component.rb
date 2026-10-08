# frozen_string_literal: true

module Dummy
  module Onboarding
    class PresskitIntroductionComponent < ViewComponent::Base
      def initialize(run:, step:)
        @run = run
        @step = step
      end

      def call
        content_tag(:div, class: "flex flex-col gap-4", data: {testid: "card-presskit-intro"}) do
          safe_join([
            render(FlatPack::PageTitle::Component.new(
                     title: "First press kit",
                     subtitle: "Subject-scoped to #{@run.scope.try(:title) || @run.scope_type}.",
                     variant: :h1
                   )),
            content_tag(:p, class: "text-sm leading-6") do
              "Each subject gets its own run. Continue to the images step."
            end
          ])
        end
      end
    end
  end
end
