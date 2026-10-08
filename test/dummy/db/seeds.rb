# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

find_or_record_child = lambda do |recordable, root_recording, parent_recording|
  RecordingStudio::Recording.find_by(
    root_recording: root_recording,
    parent_recording: parent_recording,
    recordable: recordable,
    trashed_at: nil
  ) || RecordingStudio.record!(
    action: "created",
    recordable: recordable,
    root_recording: root_recording,
    parent_recording: parent_recording
  ).recording
end

# Create the admin user (Devise actor; profile is created on first RS Users write).
user = User.find_or_create_by!(email: "admin@admin.com") do |u|
  u.password = "Password"
  u.password_confirmation = "Password"
  u.registered_with = "password" if u.respond_to?(:registered_with=)
  u.confirmed_at = Time.current if u.respond_to?(:confirmed_at=)
end
user.update!(confirmed_at: Time.current) if user.respond_to?(:confirmed_at) && user.confirmed_at.blank?

# Create the workspace recordables
workspace = Workspace.find_or_create_by!(name: "Studio Workspace")
accessible_workspace = Workspace.find_or_create_by!(name: "Client Workspace")
private_workspace = Workspace.find_or_create_by!(name: "Private Workspace")
folder = Folder.find_or_create_by!(name: "Product Docs")
page = Page.find_or_create_by!(title: "Getting Started")
admin_root = AdminRoot.find_or_create_by!(name: "Admin")

previous_actor = Current.actor
Current.actor = user

begin
  # Create the root recording
  root_recording = RecordingStudio.root_recording_for(workspace)
  accessible_root_recording = RecordingStudio.root_recording_for(accessible_workspace)
  private_root_recording = RecordingStudio.root_recording_for(private_workspace)
  admin_root_recording = RecordingStudio.root_recording_for(admin_root)

  folder_recording = find_or_record_child.call(folder, root_recording, root_recording)

  find_or_record_child.call(page, root_recording, folder_recording)

  # Grant the seeded admin owner access so workspace-scoped flows can start.
  [root_recording, accessible_root_recording, admin_root_recording].each do |recording|
    result = RecordingStudioAccessible.bootstrap_owner_access!(
      recording: recording,
      actor: user
    )
    raise result.error if result.failure?
  end
ensure
  Current.actor = previous_actor
end

# Seed onboarding analytics fixtures (runs, step progress, failed provision).
Current.actor = user
begin
  demo_users = 3.times.map do |i|
    User.find_or_create_by!(email: "onboarding-demo-#{i}@example.com") do |u|
      u.password = "Password"
      u.password_confirmation = "Password"
      u.registered_with = "password" if u.respond_to?(:registered_with=)
      u.confirmed_at = Time.current if u.respond_to?(:confirmed_at=)
    end.tap do |u|
      u.update!(confirmed_at: Time.current) if u.respond_to?(:confirmed_at) && u.confirmed_at.blank?
    end
  end

  demo_users.each_with_index do |demo_user, i|
    next if RecordingStudioOnboarding::FlowRun.open_runs.for_flow("account_setup")
                                                  .where(initiating_actor: demo_user).exists? ||
            RecordingStudioOnboarding::FlowRun.where(initiating_actor: demo_user, flow_key: "account_setup").exists?

    run = RecordingStudioOnboarding.start(:account_setup, actor: demo_user)
    RecordingStudioOnboarding.mark_viewed(run, actor: demo_user)
    next if i.zero?

    RecordingStudioOnboarding.advance(run, from: "welcome", actor: demo_user)
    run.reload
    RecordingStudioOnboarding.mark_viewed(run, actor: demo_user)
    next if i == 1

    RecordingStudioOnboarding.advance(run, from: "workspace_details", actor: demo_user)
    run.reload
    RecordingStudioOnboarding.mark_viewed(run, actor: demo_user)
    RecordingStudioOnboarding.advance(run, from: "complete", actor: demo_user)
  end

  dismiss_user = User.find_or_create_by!(email: "onboarding-dismiss@example.com") do |u|
    u.password = "Password"
    u.password_confirmation = "Password"
  end
  unless RecordingStudioOnboarding::FlowRun.where(initiating_actor: dismiss_user, status: "dismissed").exists?
    run = RecordingStudioOnboarding.start(:account_setup, actor: dismiss_user)
    RecordingStudioOnboarding.mark_viewed(run, actor: dismiss_user)
    RecordingStudioOnboarding.dismiss(run, actor: dismiss_user)
  end

  RecordingStudioOnboarding::ProvisioningExecution.find_or_create_by!(
    provisioner: "new_registration",
    idempotency_key: "seed-failed-provision"
  ) do |execution|
    execution.actor = user
    execution.status = "failed"
    execution.failure_details = { "error_class" => "RuntimeError", "message" => "seeded failure for admin demo" }
    execution.started_at = Time.current
    execution.completed_at = Time.current
  end
ensure
  Current.actor = previous_actor
end

puts "Seeded: admin@admin.com / Password"
puts "Seeded: Workspace '#{workspace.name}' with root recording ##{root_recording.id}"
puts "Seeded: Workspace '#{accessible_workspace.name}' with root recording ##{accessible_root_recording.id}"
puts "Seeded: Workspace '#{private_workspace.name}' with root recording ##{private_root_recording.id}"
puts "Seeded: AdminRoot '#{admin_root.name}' with root recording ##{admin_root_recording.id}"
puts "Seeded: Folder '#{folder.name}' and page '#{page.title}'"
puts "Seeded: onboarding runs=#{RecordingStudioOnboarding::FlowRun.count} " \
     "progress=#{RecordingStudioOnboarding::StepProgress.count} " \
     "provisions=#{RecordingStudioOnboarding::ProvisioningExecution.count}"
