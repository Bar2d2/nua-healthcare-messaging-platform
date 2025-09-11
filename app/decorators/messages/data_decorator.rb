# frozen_string_literal: true

module Messages
  # Handles data calculations and conversation metrics for message decorators.
  # Provides methods for analyzing conversation data and computing derived metrics.
  module DataDecorator
    # == Conversation Analytics ==

    # Get the total number of messages in the conversation thread.
    def conversation_thread_count
      conversation_messages.count
    end

    # Get the timestamp of the last activity in the conversation.
    def conversation_last_activity
      conversation_messages.map(&:created_at).max
    end

    # Check if conversation has any unread messages.
    def conversation_has_unread?
      conversation_messages.any? { |msg| !msg.read }
    end

    # Calculates time span between first and last message in conversation.
    # Returns 0 for single-message conversations.
    def conversation_duration
      sorted_messages = conversation_messages.sort_by(&:created_at)
      return 0 if sorted_messages.count < 2

      sorted_messages.last.created_at - sorted_messages.first.created_at
    end
  end
end
