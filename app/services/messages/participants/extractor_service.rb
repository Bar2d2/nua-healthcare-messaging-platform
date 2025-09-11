# frozen_string_literal: true

module Messages
  module Participants
    # Extracts participants from messages for medical communication system.
    # Provides centralized logic for participant extraction to eliminate code duplication.
    class ExtractorService
      attr_reader :messages

      def initialize(messages)
        @messages = Array(messages)
      end

      # == Public Interface ==

      # Extract all unique participants from messages
      def call
        extract_all_participants.uniq
      end

      class << self
        # Extract participants from a single message (class method for convenience)
        def from_message(message)
          return [] unless message

          outbox_user = message.outbox&.user
          inbox_user = message.inbox&.user

          [outbox_user, inbox_user].compact
        end

        # Extract participants from multiple messages (class method for convenience)
        def from_messages(messages)
          new(messages).call
        end
      end

      private

      # == Private Implementation ==

      # Extract all participants from all messages
      def extract_all_participants
        participants = []

        messages.each do |message|
          participants.concat(self.class.from_message(message))
        end

        participants
      end
    end
  end
end
