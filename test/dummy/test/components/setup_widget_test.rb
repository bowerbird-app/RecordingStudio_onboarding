# frozen_string_literal: true

require "test_helper"

class SetupWidgetTest < ViewComponent::TestCase
  Context = Struct.new(:actor, :label, keyword_init: true)

  setup do
    @original = RecordingStudioOnboarding.configuration
    RecordingStudioOnboarding.reset_for_tests!
    @user = User.create!(
      email: "widget-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @context = Context.new(actor: @user, label: "Almost there")
  end

  teardown do
    RecordingStudioOnboarding.reset_for_tests!(configuration: @original)
  end

  test "the widget is registered once when dashboard is loaded" do
    widget = RecordingStudioDashboard.registry.widget(:onboarding_setup)

    assert_equal RecordingStudioOnboarding::SetupWidget, widget.component
    assert_equal :hide, widget.empty_state.policy
    assert_nil RecordingStudioOnboarding::SetupWidget.register_dashboard_widget!
  end

  test "prepare hides a checklist that does not apply or is complete" do
    register_list(:hidden, check: ->(*) { false }, applies: ->(*) { false })
    hidden = RecordingStudioOnboarding::SetupWidget.prepare(@context, { checklist: :hidden })
    assert_equal :empty, hidden.state

    register_list(:finished, check: ->(*) { true })
    finished = RecordingStudioOnboarding::SetupWidget.prepare(@context, { checklist: :finished })
    assert_equal :empty, finished.state

    shown = RecordingStudioOnboarding::SetupWidget.prepare(
      @context,
      { checklist: :finished, show_complete: true }
    )
    assert_equal :content, shown.state
    render_inline RecordingStudioOnboarding::SetupWidget.new(preparation: shown)
    assert_includes rendered_content, "Nothing left. Nice work."
  end

  test "prepare renders remaining items and resolves a title proc" do
    RecordingStudioOnboarding.configure do |config|
      config.checklist :open do
        scope :user
        item :name, check: ->(*) { false }, next_step: "Add a name", link: "https://example.com/name"
        item :photo, check: ->(*) { false }, next_step: "Add a photo", link: "https://example.com/photo"
      end
    end
    preparation = RecordingStudioOnboarding::SetupWidget.prepare(
      @context,
      {
        checklist: :open,
        title: ->(ctx) { ctx.label },
        link: ->(ctx) { "/setup/#{ctx.label.parameterize}" }
      }
    )

    assert_equal :content, preparation.state
    assert_instance_of RecordingStudioOnboarding::SetupWidget::Source, preparation.data
    assert_equal "Almost there", preparation.data.title
    assert_equal ["Add a name", "Add a photo"], preparation.data.status.remaining.map(&:next_step)

    render_inline RecordingStudioOnboarding::SetupWidget.new(preparation: preparation)
    assert_rendered "h2", text: "Almost there"
    assert_rendered "[data-testid=setup-item-name] a", text: "Add a name", href: "https://example.com/name"
    assert_rendered "[data-testid=setup-item-photo] a", text: "Add a photo", href: "https://example.com/photo"
    assert_rendered "a", text: "See your setup", href: "/setup/almost-there"
    refute_includes rendered_content, "bg-[var(--surface-background-color)]"
  end

  test "prepare hides a workspace checklist the person cannot view" do
    workspace = Workspace.create!(name: "Closed room #{SecureRandom.hex(4)}")
    RecordingStudioOnboarding.configure do |config|
      config.checklist :closed do
        scope :workspace
        item :named,
          check: ->(*) { false },
          next_step: "Give the workspace a name",
          link: "https://example.com/workspace"
      end
    end

    preparation = RecordingStudioOnboarding::SetupWidget.prepare(
      @context,
      { checklist: :closed, subject: ->(*) { workspace } }
    )

    assert_equal :empty, preparation.state
  end

  private

  def assert_rendered(selector, text:, href: nil)
    node = Nokogiri::HTML.fragment(rendered_content).css(selector).find { |candidate| candidate.text.include?(text) }
    assert node, "expected #{selector} containing #{text.inspect}"
    assert_equal href, node["href"] if href
  end

  def register_list(name, check:, applies: nil)
    RecordingStudioOnboarding.configure do |config|
      config.checklist name do
        scope :user
        applies_to applies if applies
        item :name, check: check, next_step: "Add a name", link: "https://example.com/name"
      end
    end
  end
end
