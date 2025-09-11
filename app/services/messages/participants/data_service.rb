# frozen_string_literal: true

module Messages
  module Participants
    # Extracts and queries conversation participants for medical communication system.
    # Provides role-based filtering and participant analytics.
    class DataService
      attr_reader :messages

      def initialize(messages)
        @messages = Array(messages)
      end

      # == Public Interface ==

      # Get all unique participants from messages
      def all_participants
        extract_participants
      end

      # Get participants filtered by role
      def participants_by_role(role)
        all_participants.select { |user| user.role == role.to_s }
      end

      # Get all doctors from participants
      def doctors
        participants_by_role(:doctor)
      end

      # Get all patients from participants
      def patients
        participants_by_role(:patient)
      end

      # Get all admins from participants
      def admins
        participants_by_role(:admin)
      end

      # Get unique user IDs from all participants
      def unique_user_ids
        all_participants.map(&:id).uniq
      end

      # Get all participant users (alias for all_participants)
      def participants
        all_participants
      end

      # Check if any doctors are involved in conversation
      def doctor?
        doctors.any?
      end

      # Check if any patients are involved in conversation
      def patient?
        patients.any?
      end

      # Get participant count by role
      def participant_count_by_role
        {
          doctors: doctors.count,
          patients: patients.count,
          admins: admins.count,
          total: all_participants.count
        }
      end

      # == Doctor Finding Methods ==

      # Find doctor in a single message
      def find_doctor_in_message(message)
        outbox_user = message.outbox.user
        return outbox_user if outbox_user.is_doctor?

        inbox_user = message.inbox.user
        return inbox_user if inbox_user.is_doctor?

        nil
      end

      # Find doctor in conversation (first doctor found)
      def find_doctor_in_conversation
        messages.each do |msg|
          doctor = find_doctor_in_message(msg)
          return doctor if doctor
        end
        nil
      end

      # Get first doctor from participants
      def first_doctor
        doctors.first
      end

      private

      # Extract unique participants from messages
      def extract_participants
        Messages::Participants::ExtractorService.from_messages(messages)
      end
    end
  end
end
