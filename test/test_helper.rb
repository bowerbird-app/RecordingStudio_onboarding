# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require_relative "simplecov_helper"
require "minitest/autorun"
begin
  require "minitest/mock"
rescue LoadError
  # Minitest 6 extracts Object#stub into the minitest-mock gem. The dummy
  # bundle does not load that gem; only the gem suite stubs methods.
end
require "rails"
require "active_support/time"
Time.zone ||= "UTC"
require "recording_studio_onboarding"

module BuildRecordHelper
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

Minitest::Test.include(BuildRecordHelper)
