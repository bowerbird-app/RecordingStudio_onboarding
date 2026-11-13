# frozen_string_literal: true

require "test_helper"

class HostSubmitButtonTest < ViewComponent::TestCase
  test "add images submit matches the gem continue placement" do
    scope = Struct.new(:title).new("Press kit")
    run = Struct.new(:id, :scope).new("run-1", scope)
    step = Struct.new(:key).new(:add_images)

    render_inline Dummy::Onboarding::AddImagesComponent.new(run: run, step: step)

    fragment = Nokogiri::HTML.fragment(rendered_content)
    row = fragment.at_css("[data-testid='host-submit']")
    assert row
    classes = row["class"].to_s.split
    assert_includes classes, "mt-10"
    assert_includes classes, "justify-end"
    button = row.at_css("button[type='submit']")
    assert_equal "Save title", button.text.squish
    refute_includes button["class"].to_s.split, "w-full"
  end
end
