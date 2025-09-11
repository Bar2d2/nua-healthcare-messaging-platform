# frozen_string_literal: true

module Broadcasting
  # Handles new message delivery broadcasting
  # Manages real-time message delivery to inbox, outbox, and conversation streams
  class MessageDeliveryService
    attr_reader :message

    def initialize(message)
      @message = message
    end

    # == Public Interface ==

    # Main broadcasting method for new messages
    def broadcast_new_message
      # Broadcast to recipient's inbox
      broadcast_to_recipient_inbox

      # Broadcast to sender's outbox
      broadcast_to_sender_outbox

      # Broadcast to general messages stream
      broadcast_to_messages_stream

      # Broadcast to conversation thread (if applicable)
      broadcast_to_conversation_thread
    end

    class << self
      # Convenience class method
      def broadcast_new_message(message)
        new(message).broadcast_new_message
      end
    end

    private

    # == Message Broadcasting Methods ==

    # Broadcast to recipient's inbox stream
    def broadcast_to_recipient_inbox
      recipient_user = message.recipient_user
      return unless recipient_user

      Broadcasting::TurboStreamsService.broadcast_prepend_to(
        Broadcasting::TurboStreamsService.inbox_stream(recipient_user.inbox),
        target: 'inbox-list',
        partial: 'messages/partials/list/received_message_item',
        locals: { message: message }
      )

      # Enqueue pagination update for performance
      Broadcasting::PaginationUpdatesService.enqueue_message_pagination_update(recipient_user, :inbox)
    end

    # Broadcast to sender's outbox stream
    def broadcast_to_sender_outbox
      sender_user = message.sender_user
      return unless sender_user

      Broadcasting::TurboStreamsService.broadcast_prepend_to(
        Broadcasting::TurboStreamsService.outbox_stream(sender_user),
        target: 'outbox-list',
        partial: 'messages/partials/list/sent_message_item',
        locals: { message: message }
      )

      # Enqueue pagination update for performance
      Broadcasting::PaginationUpdatesService.enqueue_message_pagination_update(sender_user, :outbox)
    end

    # Broadcast to general messages stream
    def broadcast_to_messages_stream
      # Determine the correct partial based on message context
      partial_name = if message.inbox
                       'messages/partials/list/received_message_item'
                     else
                       'messages/partials/list/sent_message_item'
                     end

      Broadcasting::TurboStreamsService.broadcast_append_to(
        Broadcasting::TurboStreamsService.messages_stream,
        target: 'messages-list',
        partial: partial_name,
        locals: { message: message }
      )
    end

    # Broadcast to conversation thread (if applicable)
    def broadcast_to_conversation_thread
      return if message.parent_message.blank?

      Broadcasting::TurboStreamsService.broadcast_prepend_to(
        Broadcasting::TurboStreamsService.conversation_stream(conversation_root),
        target: 'conversation-thread',
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
