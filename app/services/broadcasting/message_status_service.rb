# frozen_string_literal: true

module Broadcasting
  # Handles message status update broadcasting (read status changes)
  # Manages real-time updates when messages are marked as read/unread
  class MessageStatusService
    attr_reader :message

    def initialize(message)
      @message = message
    end

    # == Public Interface ==

    # Broadcast message status updates
    def broadcast_status_update
      # Update message in recipient's inbox
      broadcast_to_recipient_inbox

      # Update message in conversation thread (if applicable)
      broadcast_to_conversation_thread
    end

    class << self
      # Convenience class method
      def broadcast_status_update(message)
        new(message).broadcast_status_update
      end
    end

    private

    # == Status Update Broadcasting ==

    # Broadcast read status update to recipient's inbox
    def broadcast_to_recipient_inbox
      recipient_user = message.recipient_user
      return unless recipient_user

      message_id = ActionView::RecordIdentifier.dom_id(message)
      Broadcasting::TurboStreamsService.broadcast_replace_to(
        Broadcasting::TurboStreamsService.inbox_stream(recipient_user.inbox),
        target: message_id,
        partial: 'messages/partials/list/received_message_item',
        locals: { message: message }
      )
    end

    # Broadcast status update to conversation thread (if applicable)
    def broadcast_to_conversation_thread
      return if message.parent_message.blank?

      message_id = ActionView::RecordIdentifier.dom_id(message)
      Broadcasting::TurboStreamsService.broadcast_replace_to(
        Broadcasting::TurboStreamsService.conversation_stream(conversation_root),
        target: message_id,
        partial: 'messages/partials/conversation/message',
        locals: { message: message }
      )
    end

    # Get conversation root for broadcasting
    def conversation_root
      @conversation_root ||= message.conversation_root
    end
  end
end
