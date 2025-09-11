# frozen_string_literal: true

module Messages
  # Handles conversation-related data access and navigation for message decorators.
  # Provides methods for accessing conversation participants, messages, and metadata.
  module ConversationDecorator
    # == Conversation Navigation ==

    # Find the root message of this conversation thread.
    def conversation_root
      @conversation_root ||= conversation_service.root
    end

    # Get the user who started this conversation.
    def conversation_owner
      @conversation_owner ||= conversation_service.owner
    end

    # Get all unique participants in this conversation.
    def conversation_participants
      @conversation_participants ||= conversation_service.participants
    end

    # Get all messages in this conversation thread, ordered chronologically.
    def conversation_messages
      @conversation_messages ||= conversation_service.messages
    end

    # Find the doctor involved in this conversation (if any).
    def conversation_doctor
      @conversation_doctor ||= conversation_service.doctor
    end

    # Get conversation statistics for display and analysis.
    def conversation_stats
      @conversation_stats ||= conversation_service.stats
    end

    private

    # Get conversation service instance for conversation operations.
    def conversation_service
      @conversation_service ||= Messages::Conversations::DataService.new(@message)
    end
  end
end
