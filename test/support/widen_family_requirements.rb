# frozen_string_literal: true

# Sibling gemspecs still cap recording_studio below 6.1, Accessible below 0.24,
# Attachable below 0.22, Publishable below 0.13, or Trashable below 0.12.
# Bundler evaluates those gemspecs in this process. Relax the requirement
# before resolution so the pinned GitHub tags can activate.
module WidenFamilyRequirements
  SKIP = %w[recording_studio recording_studio_onboarding].freeze

  TARGETS = {
    "recording_studio" => "6.3.0",
    "recording_studio_accessible" => "0.24.0",
    "recording_studio_admin" => "2.8.2",
    "recording_studio_attachable" => "0.22.0",
    "recording_studio_publishable" => "0.13.0",
    "recording_studio_trashable" => "0.12.2",
    "recording_studio_user" => "0.26.6",
    "view_component" => "4.14.0"
  }.freeze

  REPLACEMENTS = {
    "recording_studio" => [">= 6.1.0"],
    "recording_studio_accessible" => [">= 0.11"],
    "recording_studio_admin" => [">= 2.0"],
    "recording_studio_attachable" => [">= 0.7"],
    "recording_studio_publishable" => [">= 0.6"],
    "recording_studio_trashable" => [">= 0.10"],
    "recording_studio_user" => [">= 0.18.0"],
    "view_component" => [">= 4.14", "< 5"]
  }.freeze

  module SpecificationPatch
    def add_dependency(name, *requirements)
      super(name, *patched_requirements(name.to_s, requirements))
    end

    private

    def patched_requirements(name, requirements)
      return requirements if SKIP.include?(self.name.to_s)

      replacement = REPLACEMENTS[name]
      return requirements unless replacement
      return requirements if requirements_allow?(requirements, TARGETS[name])

      replacement
    end

    def requirements_allow?(requirements, version)
      return true if version.nil?

      Gem::Requirement.new(requirements).satisfied_by?(Gem::Version.new(version))
    end
  end
end

Gem::Specification.prepend(WidenFamilyRequirements::SpecificationPatch)
