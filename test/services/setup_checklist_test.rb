# frozen_string_literal: true

require "test_helper"
require "recording_studio_onboarding/services/evaluate_checklist"

class SetupChecklistTest < Minitest::Test
  def setup
    @original = RecordingStudioOnboarding.configuration
    RecordingStudioOnboarding.reset_for_tests!
    @actor = build_record("User", "actor-1")
    @other = build_record("User", "actor-2")
  end

  def teardown
    RecordingStudioOnboarding.reset_for_tests!(configuration: @original)
  end

  def test_checklist_registers_items_scope_and_applies_to
    register_studio

    definition = RecordingStudioOnboarding.configuration.checklist_for(:studio)
    assert RecordingStudioOnboarding.configuration.checklist_registered?(:studio)
    assert_equal :user, definition.scope
    assert_equal %i[email press_kit], definition.items.map(&:key)
    assert_equal [:studio], RecordingStudioOnboarding.configuration.to_h.fetch(:checklists)
    assert_equal 5.minutes, RecordingStudioOnboarding.configuration.setup_recheck_interval
    assert_empty RecordingStudioOnboarding.configuration.before_onboarding_gates
  end

  def test_checklist_requires_a_name_items_and_absolute_link
    assert_raises(ArgumentError) { RecordingStudioOnboarding.configuration.checklist(nil) { item_email } }
    assert_raises(ArgumentError) { RecordingStudioOnboarding.configuration.checklist(:studio) }
    assert_raises(ArgumentError) do
      RecordingStudioOnboarding.configuration.checklist(:empty) { scope :user }
    end
    assert_raises(ArgumentError) do
      RecordingStudioOnboarding.configuration.checklist(:bad_scope) do
        scope :team
        item :email, check: ->(*) { true }, next_step: "Confirm your email", link: "https://example.com/email"
      end
    end
    assert_raises(ArgumentError) do
      RecordingStudioOnboarding.configuration.checklist(:relative) do
        item :email, check: ->(*) { true }, next_step: "Confirm your email", link: "email"
      end
    end
  end

  def test_item_link_accepts_a_path_or_host_callable_and_defaults_the_icon
    RecordingStudioOnboarding.configure do |config|
      config.checklist :studio do
        scope :user
        item :email,
             check: ->(*) { false },
             next_step: "Confirm your email",
             link: "/account/email"
        item :press_kit,
             check: ->(*) { false },
             next_step: "Publish your first press kit",
             link: -> { "/press_kits/new" },
             icon: :queue_list
      end
    end

    status = evaluate(:studio)
    email, press = status.remaining

    assert_equal "/account/email", email.link
    assert_equal :queue_list, email.icon
    assert_equal "/press_kits/new", press.link
    assert_equal :queue_list, press.icon
  end

  def test_status_lists_the_next_item_done_and_remaining
    register_studio(email_done: true, press_done: false)
    status = evaluate(:studio)

    assert_equal :studio, status.checklist
    assert status.applicable?
    refute status.complete?
    assert_equal :press_kit, status.next_item.key
    assert_equal ["Confirm the email on your account"], status.done.map(&:next_step)
    assert_equal ["Publish your first press kit"], status.remaining.map(&:next_step)
    assert_equal "https://example.com/press", status.next_item.link
  end

  def test_applies_to_hides_an_item_and_drops_it_from_completeness
    register_studio(email_done: true, press_applies: false, press_done: false)
    status = evaluate(:studio)

    assert status.complete?
    assert_nil status.next_item
    assert_equal [:email], status.done.map(&:key)
    assert_empty status.remaining
  end

  def test_checklist_applies_to_hides_the_whole_list
    RecordingStudioOnboarding.configure do |config|
      config.checklist :staff do
        applies_to ->(actor, _scope) { actor.id == "staff" }
        item :email, check: ->(*) { false }, next_step: "Confirm your email", link: "https://example.com/email"
      end
    end

    hidden = evaluate(:staff, actor: @actor)
    refute hidden.applicable?
    assert hidden.complete?
    assert_empty hidden.done
    assert_empty hidden.remaining
  end

  def test_multiple_checklists_stay_independent
    register_studio(email_done: false, press_applies: false)
    RecordingStudioOnboarding.configure do |config|
      config.checklist :billing do
        item :card, check: ->(*) { true }, next_step: "Add a card", link: "https://example.com/card"
      end
    end

    studio = evaluate(:studio)
    billing = evaluate(:billing)

    refute studio.complete?
    assert_equal :email, studio.next_item.key
    assert billing.complete?
    assert_equal :card, billing.done.first.key
  end

  def test_a_raising_check_counts_as_not_done
    RecordingStudioOnboarding.configure do |config|
      config.checklist :studio do
        item :email,
             check: ->(*) { raise "profile store down" },
             next_step: "Confirm the email on your account",
             link: ->(*) { "https://example.com/email" }
      end
    end

    status = evaluate(:studio)
    refute status.complete?
    refute status.remaining.first.done?
    assert_equal "https://example.com/email", status.remaining.first.link
  end

  def test_a_bad_link_does_not_raise
    RecordingStudioOnboarding.configure do |config|
      config.checklist :studio do
        item :email, check: ->(*) { true }, next_step: "Confirm your email", link: ->(*) { "relative" }
      end
    end

    status = evaluate(:studio)
    assert_nil status.done.first.link
    assert status.complete?
  end

  def test_sign_in_hook_skips_when_warden_is_absent
    RecordingStudioOnboarding::SignInRecheck.reset_for_tests!
    RecordingStudioOnboarding::SignInRecheck.stub(:warden_manager, nil) do
      RecordingStudioOnboarding::SignInRecheck.install!
    end
    refute RecordingStudioOnboarding::SignInRecheck.installed?
  ensure
    RecordingStudioOnboarding::SignInRecheck.reset_for_tests!
  end

  def test_unknown_checklist_raises_key_error
    error = assert_raises(KeyError) do
      RecordingStudioOnboarding.setup_status(:missing, actor: @actor)
    end
    assert_match(/missing/, error.message)
  end

  def test_saved_snapshot_rebuilds_done_and_remaining
    register_studio
    definition = RecordingStudioOnboarding.configuration.checklist_for(:studio)
    row = Struct.new(:applicable, :complete, :items, :checked_at).new(
      true,
      false,
      [{ "key" => "email", "next_step" => "Confirm the email on your account", "link" => "https://example.com/email",
         "done" => true }],
      Time.utc(2026, 11, 18, 12, 0, 0)
    )

    status = RecordingStudioOnboarding::SetupSnapshot.load(definition, row)
    refute status.complete?
    assert_equal :email, status.done.first.key
    assert_equal row.checked_at, status.checked_at
  end

  private

  def register_studio(email_done: true, press_done: false, press_applies: true)
    email_flag = email_done
    press_flag = press_done
    applies = press_applies
    RecordingStudioOnboarding.configure do |config|
      config.checklist :studio do
        scope :user
        item :email,
             check: ->(*) { email_flag },
             next_step: "Confirm the email on your account",
             link: "https://example.com/email"
        item :press_kit,
             applies_to: ->(*) { applies },
             check: ->(*) { press_flag },
             next_step: "Publish your first press kit",
             link: "https://example.com/press"
      end
    end
  end

  def evaluate(name, actor: @actor)
    definition = RecordingStudioOnboarding.configuration.checklist_for(name)
    RecordingStudioOnboarding::Services::EvaluateChecklist.call(definition, actor: actor, scope: actor)
  end

  def item_email
    item :email, check: ->(*) { true }, next_step: "Confirm your email", link: "https://example.com/email"
  end
end
