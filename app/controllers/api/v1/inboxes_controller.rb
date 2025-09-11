# frozen_string_literal: true

module Api
  module V1
    class InboxesController < BaseController
      # GET /api/v1/inbox/messages
      def messages
        messages = current_user.inbox.messages.includes(:outbox, :parent_message)
                               .order(created_at: :desc)
                               .limit(50)
        render_collection(messages, MessageSerializer)
      end

      # GET /api/v1/inbox/conversations
      def conversations
        conversation_roots = current_user.inbox.messages
                                         .where(parent_message_id: nil)
                                         .includes(:outbox, :replies)
                                         .order(created_at: :desc)
                                         .limit(10)
        render_collection(conversation_roots, ConversationSerializer)
      end

      # GET /api/v1/inbox/unread
      def unread
        unread_count = current_user.inbox.messages.where(read: false).count
        render_success({ unread_count: unread_count })
      end
    end
  end
end
