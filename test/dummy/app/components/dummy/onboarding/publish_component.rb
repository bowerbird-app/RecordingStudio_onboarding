# frozen_string_literal: true

module Dummy
  module Onboarding
    class PublishComponent < ViewComponent::Base
      def initialize(run:, step:)
        @run = run
        @step = step
      end

      def call
        content_tag(:div, class: "flex flex-col gap-4", data: {testid: "card-publish"}) do
          safe_join([
            render(FlatPack::PageTitle::Component.new(
                     title: "Publish",
                     subtitle: "Last step for this press kit subject.",
                     variant: :h2
                   )),
            content_tag(:p, class: "text-sm leading-6") do
              "Continue completes the subject-scoped flow."
            end
          ])
        end
      end
    end
  end
end
