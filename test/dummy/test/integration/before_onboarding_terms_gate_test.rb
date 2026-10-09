# frozen_string_literal: true

require "test_helper"

class BeforeOnboardingTermsGateTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @original_configuration = RecordingStudioOnboarding.instance_variable_get(:@configuration)
    RecordingStudioOnboarding.instance_variable_set(:@configuration, RecordingStudioOnboarding::Configuration.new)
    RecordingStudioOnboarding.configure do |config|
      config.current_actor = ->(controller) { controller.current_user }
      config.provision :new_registration, with: "Dummy::ProvisionRegistration"
      config.flow :account_setup do
        scope :user
        progress :segments
        dismissible true
        version 1
        after_complete "/"
        after_dismiss "/flows"
        step :welcome,
          component: "Dummy::Onboarding::WelcomeComponent",
          controls: %i[continue exit]
        step :workspace_details,
          component: "Dummy::Onboarding::WorkspaceDetailsComponent",
          controls: %i[back skip exit],
          skippable: true
        step :complete,
          component: "Dummy::Onboarding::CompleteComponent",
          controls: %i[continue],
          show_progress: false
      end
    end

    @admin = User.create!(
      email: "terms-admin-#{SecureRandom.hex(4)}@example.com",
      password: "Password",
      password_confirmation: "Password",
      registered_with: "password",
      confirmed_at: Time.current
    )
    @workspace = Workspace.create!(name: "Terms Gate Workspace #{SecureRandom.hex(4)}")
    Current.actor = @admin
    @root = RecordingStudio.root_recording_for(@workspace)
    RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @admin).value!
    ensure_published_terms!
    RecordingStudioOnboarding::Gates::TermsAndConditions.register_if_present!
  end

  teardown do
    RecordingStudioOnboarding.instance_variable_set(:@configuration, @original_configuration)
    Current.actor = nil
  end

  test "terms installed and due sends run page to Agree then back after accept" do
    user = pending_terms_user("terms-due")
    run = RecordingStudioOnboarding.start(:account_setup, actor: user)
    sign_in user

    get recording_studio_onboarding.run_path(run)
    assert_redirected_to recording_studio_terms_and_conditions.acceptance_path
    follow_redirect!
    assert_response :success
    assert_match(/Terms|Agree|accept/i, response.body)

    post recording_studio_terms_and_conditions.acceptance_path
    assert_response :redirect
    follow_redirect!
    assert_includes response.request.path, "/onboarding/runs/#{run.id}"
    assert_response :success
    assert_select "[data-testid=onboarding-run], [data-testid=onboarding-progress]", minimum: 1
  end

  test "terms installed with nothing due shows onboarding as today" do
    user = pending_terms_user("terms-clear")
    accept_all_terms!(user)
    run = RecordingStudioOnboarding.start(:account_setup, actor: user)
    sign_in user

    get recording_studio_onboarding.run_path(run)
    assert_response :success
    refute_equal recording_studio_terms_and_conditions.acceptance_path, path
    assert_select "[data-testid=onboarding-progress], [data-testid=onboarding-run]", minimum: 1
  end

  test "start API creates the run while Agree blocks the user-facing path" do
    user = pending_terms_user("terms-start")
    run = RecordingStudioOnboarding.start(:account_setup, actor: user)
    assert run.open?
    assert RecordingStudioTermsAndConditions.requires_acceptance?(user, @workspace)

    sign_in user
    get recording_studio_onboarding.run_path(run)
    assert_redirected_to recording_studio_terms_and_conditions.acceptance_path

    get "/flows"
    assert_redirected_to recording_studio_terms_and_conditions.acceptance_path
  end

  test "without before_onboarding gates onboarding helper is a no-op" do
    user = pending_terms_user("terms-ungated")
    run = RecordingStudioOnboarding.start(:account_setup, actor: user)
    RecordingStudioOnboarding.configuration.before_onboarding_gates.clear

    assert_empty RecordingStudioOnboarding.configuration.before_onboarding_gates
    path = RecordingStudioOnboarding.before_onboarding_redirect_to(
      nil,
      actor: user,
      return_path: recording_studio_onboarding.run_path(run)
    )
    assert_nil path
  end

  test "registration.completed still provisions while terms are due" do
    email = "terms-provision-#{SecureRandom.hex(4)}@example.com"

    post new_user_registration_path, params: { user: { email: email } }
    follow_redirect!

    assert_difference -> { RecordingStudioOnboarding::ProvisioningExecution.count }, 1 do
      post user_registration_path, params: {
        user: { email: email, password: "Password123!" }
      }
    end

    user = User.find_by!(email: email)
    execution = RecordingStudioOnboarding::ProvisioningExecution.find_by!(
      provisioner: "new_registration",
      actor: user
    )
    assert_equal "completed", execution.status
  end

  private

  def pending_terms_user(label)
    User.create!(
      email: "#{label}-#{SecureRandom.hex(4)}@example.com",
      password: "Password",
      password_confirmation: "Password",
      registered_with: "password",
      confirmed_at: Time.current
    ).tap do |u|
      assert RecordingStudioTermsAndConditions.requires_acceptance?(u, @workspace),
             "expected #{u.email} to owe live Terms"
    end
  end

  def accept_all_terms!(actor)
    RecordingStudioTermsAndConditions.pending_published_list(actor, @workspace).each do |terms|
      RecordingStudioTermsAndConditions.accept!(actor, terms, { "source" => "test" })
    end
    refute RecordingStudioTermsAndConditions.requires_acceptance?(actor, @workspace)
  end

  def ensure_published_terms!
    recording = RecordingStudioTermsAndConditions::KindPresence
                .recordings_for(@root, kind: RecordingStudioTermsAndConditions::Terms::KIND_TERMS)
                .max_by { |row| row.created_at || Time.at(0) }

    if recording.blank?
      recording = @root.record(
        RecordingStudioTermsAndConditions::Terms,
        actor: @admin
      ) do |terms|
        terms.title = RecordingStudioTermsAndConditions::SampleTerms::TITLE
        terms.body = RecordingStudioTermsAndConditions::SampleTerms::BODY
        terms.kind = RecordingStudioTermsAndConditions::Terms::KIND_TERMS
      end
    end

    return if recording.currently_published?

    RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: recording,
      attributes: { slug: "studio-terms-#{SecureRandom.hex(4)}", status: "published" }
    ).value!
  end
end
