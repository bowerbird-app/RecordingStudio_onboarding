# frozen_string_literal: true

module Dummy
  module Onboarding
    # Wide welcome card with a dominant illustration plane.
    class WelcomeComponent < ViewComponent::Base
      def initialize(run:, step:)
        @run = run
        @step = step
      end

      def call
        content_tag(:div, class: "flex w-full flex-col gap-6", data: {testid: "card-welcome"}) do
          safe_join([
            content_tag(
              :div,
              class: "flex min-h-48 w-full items-center justify-center rounded-[var(--radius-md)] " \
                     "bg-[var(--surface-muted-background-color)] px-6 py-10 text-center"
            ) do
              content_tag(:p, "Welcome illustration", class: "text-lg font-medium opacity-70")
            end,
            render(FlatPack::PageTitle::Component.new(
                     title: "Welcome aboard",
                     subtitle: "A wide first step — set up your account in a few minutes.",
                     variant: :h1
                   )),
            content_tag(:p, class: "text-sm leading-6") do
              "This card owns its layout. Controls below are provided by the onboarding engine."
            end
          ])
        end
      end
    end
  end
end
