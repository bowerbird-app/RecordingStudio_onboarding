# frozen_string_literal: true

require "test_helper"
require "securerandom"

# Load the service without forcing the ActiveRecord model (gem unit suite has no DB).
module RecordingStudioOnboarding
  class ProvisioningExecution
    STATUSES = %w[pending running completed failed].freeze
  end
end
require "recording_studio_onboarding/services/provision"

class ProvisionRegistryTest < Minitest::Test
  class FakeHandler
    class << self
      attr_accessor :calls

      def call(**kwargs)
        self.calls ||= []
        calls << kwargs
        :ok
      end
    end
  end

  def setup
    @original = RecordingStudioOnboarding.configuration
    RecordingStudioOnboarding.reset_for_tests!
    FakeHandler.calls = []
  end

  def teardown
    RecordingStudioOnboarding.reset_for_tests!(configuration: @original)
  end

  def test_unregistered_provisioner_is_detectable
    refute RecordingStudioOnboarding.configuration.provisioner_registered?(:missing)
    assert_nil RecordingStudioOnboarding.configuration.provisioner_for(:missing)
  end

  def test_default_idempotency_key_uses_stable_identity
    actor = build_record("User", "aaa")
    subject = build_record("User", "aaa")
    service = RecordingStudioOnboarding::Services::Provision.new(
      :new_registration,
      actor: actor,
      subject: subject
    )

    assert_equal "new_registration:User:aaa", service.idempotency_key
  end

  def test_default_idempotency_key_includes_distinct_subject
    actor = build_record("User", "aaa")
    subject = build_record("Workspace", "bbb")
    service = RecordingStudioOnboarding::Services::Provision.new(
      :workspace_setup,
      actor: actor,
      subject: subject
    )

    assert_equal "workspace_setup:User:aaa:Workspace:bbb", service.idempotency_key
  end

  def test_initialize_rejects_unknown_keywords
    actor = build_record("User", "aaa")
    error = assert_raises(ArgumentError) do
      RecordingStudioOnboarding::Services::Provision.new(
        :new_registration,
        actor: actor,
        idempotency_ky: "typo"
      )
    end
    assert_match(/Unknown keywords: :idempotency_ky/, error.message)
  end

  def test_configure_provision_api
    RecordingStudioOnboarding.configure do |config|
      config.provision :new_registration, with: FakeHandler
    end

    assert_equal FakeHandler, RecordingStudioOnboarding.configuration.provisioner_for(:new_registration)
  end

  private

  def build_record(type_name, id)
    type = Class.new do
      define_singleton_method(:base_class) { self }
      define_singleton_method(:name) { type_name }
    end

    record = Object.new
    record.define_singleton_method(:id) { id }
    record.define_singleton_method(:class) { type }
    record
  end
end
