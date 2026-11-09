# frozen_string_literal: true

module RecordingStudioOnboarding
  module Services
    # Accessible checks for flow scopes and provision targets. Fail closed.
    module AccessibleAuthorization
      module_function

      def allowed_for_scope?(definition:, scope:, actor:)
        return false if actor.nil? || definition.nil?

        case definition.scope
        when :user
          same_record?(scope, actor)
        when :workspace, :subject
          allowed?(actor: actor, record: scope)
        else
          false
        end
      end

      def allowed?(actor:, record:, role: :view)
        return false unless defined?(RecordingStudioAccessible)
        return false if actor.nil? || record.nil?

        recording = recording_for(record)
        return false if recording.nil?

        RecordingStudioAccessible.authorized?(actor: actor, recording: recording, role: role)
      end

      def recording_for(record)
        return record if record.is_a?(RecordingStudio::Recording)
        return unless defined?(RecordingStudio::Recording)

        if defined?(RecordingStudio) && RecordingStudio.root_allowed?(record)
          RecordingStudio::Recording.find_by(recordable: record, parent_recording_id: nil)
        else
          RecordingStudio::Recording.find_by(recordable: record)
        end
      rescue StandardError
        nil
      end

      def same_record?(left, right)
        return false if left.nil? || right.nil?

        left.class.base_class == right.class.base_class && left.id == right.id
      end
    end
  end
end
