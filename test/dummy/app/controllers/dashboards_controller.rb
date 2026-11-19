# frozen_string_literal: true

class DashboardsController < ApplicationController
  def show
    @dashboard = RecordingStudioDashboard.component(:studio, context: StudioDashboardContext.new(current_user))
  end
end

class StudioDashboardContext
  attr_reader :actor

  def initialize(actor)
    @actor = actor
  end
end
