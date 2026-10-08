# frozen_string_literal: true

module Dummy
  module Onboarding
    class InviteTeammateComponent < ViewComponent::Base
      def initialize(run:, step:)
        @run = run
        @step = step
      end

      def call
        content_tag(:div, class: "flex flex-col gap-4", data: {testid: "card-invite-teammate"}) do
          safe_join([
            render(FlatPack::PageTitle::Component.new(
                     title: "Invite a teammate",
                     subtitle: "Optional — you can skip this step.",
                     variant: :h2
                   )),
            content_tag(:p, class: "text-sm leading-6") do
              "Progress uses the bar mode for this workspace flow."
            end
          ])
        end
      end
    end
  end
end
