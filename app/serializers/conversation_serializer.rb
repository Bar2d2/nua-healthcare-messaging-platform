# frozen_string_literal: true

# Serializer for Conversation objects in API responses
class ConversationSerializer < ApplicationSerializer
  def attributes
    conversation_messages = object.conversation_messages
    {
      id: object.id,
      subject: object.body.truncate(50),
      participants: object.conversation_participants.map { |user| UserSerializer.new(user).attributes },
      last_message: MessageSerializer.new(conversation_messages.last).attributes,
      message_count: conversation_messages.count,
      created_at: object.created_at
    }
  end
end
