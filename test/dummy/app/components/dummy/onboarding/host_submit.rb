# frozen_string_literal: true

module Dummy
  module Onboarding
    # Host form submit, placed like the gem Continue button.
    module HostSubmit
      def host_submit_button(text)
        content_tag(:div, class: "mt-10 flex w-full justify-end", data: { testid: "host-submit" }) do
          render(FlatPack::Button::Component.new(text: text, style: :primary, type: "submit"))
        end
      end
    end
  end
end
