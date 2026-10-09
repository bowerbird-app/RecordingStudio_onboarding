# frozen_string_literal: true

module RecordingStudioOnboarding
  module Gates
    # Soft optional gate: when RecordingStudio Terms & Conditions is loaded and
    # the actor still owes live Terms, send them to the Agree screen first.
    # Uses only RS Terms public API (requires_acceptance?, Gate.acceptance_path,
    # Gate.root_for_acceptance). Return path uses Devise store_location_for —
    # Terms has no custom query-param return URL.
    class TermsAndConditions
      def self.register_if_present!
        return unless defined?(::RecordingStudioTermsAndConditions)

        config = RecordingStudioOnboarding.configuration
        return if config.before_onboarding_gates.any?(self)

        config.before_onboarding(new)
      end

      # @return [String, nil] Agree path when terms are due, otherwise nil
      def call(controller:, actor:, return_path: nil)
        return unless defined?(::RecordingStudioTermsAndConditions)
        return if actor.blank?
        return unless controller

        root = ::RecordingStudioTermsAndConditions::Gate.root_for_acceptance(controller)
        return if root.blank?
        return unless ::RecordingStudioTermsAndConditions.requires_acceptance?(actor, root)

        remember_return_path(controller, return_path)
        ::RecordingStudioTermsAndConditions::Gate.acceptance_path(controller)
      end

      private

      def remember_return_path(controller, return_path)
        return if return_path.blank?
        return unless controller.respond_to?(:store_location_for)

        controller.store_location_for(:user, return_path)
      end
    end
  end
end
