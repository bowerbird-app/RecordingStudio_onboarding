# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

DUMMY_TEST_FILES = [
  File.expand_path("test/controllers/docs_controller_test.rb", __dir__),
  File.expand_path("test/recording_studio_declarations_test.rb", __dir__)
].freeze
DEFAULT_DUMMY_GEMFILE = File.expand_path("test/dummy/Gemfile", __dir__)
DUMMY_APP_ROOT = File.expand_path("test/dummy", __dir__)
TEST_ROOT = File.expand_path("test", __dir__)
ROOT_TEST_EXCLUSIONS = %w[
  test/controllers/docs_controller_test.rb
  test/dummy/**/*_test.rb
  test/recording_studio_declarations_test.rb
  test/rename_verification_test.rb
].freeze

def env_gemfile_path
  %w[DUMMY_GEMFILE BUNDLE_GEMFILE].each do |key|
    value = ENV.fetch(key, nil)
    return value unless value.nil? || value.empty?
  end
  nil
end

def resolve_dummy_gemfile
  configured = env_gemfile_path
  return DEFAULT_DUMMY_GEMFILE unless configured

  # Expand against the repo root so chdir into test/dummy cannot rewrite a
  # relative gemfiles/… path into test/dummy/gemfiles/….
  path = File.absolute_path?(configured) ? configured : File.expand_path(configured, __dir__)
  return path if path.end_with?("without_terms.gemfile", "test/dummy/Gemfile")

  DEFAULT_DUMMY_GEMFILE
end

DUMMY_BUNDLE_CLEARED_ENV = {
  "BUNDLE_APP_CONFIG" => nil,
  "BUNDLE_BIN_PATH" => nil,
  "BUNDLE_LOCKFILE" => nil,
  "BUNDLER_SETUP" => nil,
  "BUNDLER_VERSION" => nil,
  "RUBYLIB" => nil,
  "RUBYOPT" => nil
}.freeze

def run_command!(env, *command)
  return if Bundler.with_unbundled_env { system(env, *command) }

  raise "Command failed (#{Process.last_status.exitstatus}): #{command.join(' ')}"
end

def dummy_bundle_env
  gemfile = resolve_dummy_gemfile
  dummy_bundle_base_env(gemfile).merge(DUMMY_BUNDLE_CLEARED_ENV).tap do |env|
    env["BUNDLE_GEMFILE"] = gemfile
    env["DUMMY_GEMFILE"] = gemfile
    env["BUNDLE_PATH"] = ENV["BUNDLE_PATH"] if ENV["BUNDLE_PATH"]
  end
end

def dummy_bundle_base_env(gemfile = resolve_dummy_gemfile)
  {
    "BUNDLE_GEMFILE" => gemfile,
    "DUMMY_GEMFILE" => gemfile,
    "DISABLE_SIMPLECOV" => "true"
  }
end

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"].exclude(*ROOT_TEST_EXCLUSIONS)
  t.verbose = false
end

namespace :test do
  desc "Run rename verification tests to validate gem naming consistency"
  task :rename_verification do
    ruby "test/rename_verification_test.rb", verbose: true
  end

  desc "Run rename verification tests in verbose mode"
  task :rename_verification_verbose do
    ruby "test/rename_verification_test.rb", "--verbose", verbose: true
  end

  desc "Run dummy app integration tests under the selected dummy Gemfile"
  task :dummy do
    gemfile = resolve_dummy_gemfile
    puts "Dummy Gemfile: #{gemfile}"

    Dir.chdir(DUMMY_APP_ROOT) do
      env = dummy_bundle_env

      run_command!(env, "bundle", "exec", "bin/rails", "db:prepare")
      run_command!(env, "bundle", "exec", "bin/rails", "test")
      DUMMY_TEST_FILES.each do |test_file|
        run_command!(env, "bundle", "exec", "ruby", "-I#{TEST_ROOT}", test_file)
      end
    end
  end

  desc "Run gem and dummy app tests"
  task all: %i[test dummy]
end

namespace :app do
  desc "Run all tests for the gem"
  task test: "test:all"
end

task default: :test
