# frozen_string_literal: true

module Messages
  module Conversations
    # Manages conversation state changes and user interactions.
    class ActionsService
      class << self
        def mark_conversation_as_read(message, current_user)
          return unless current_user&.inbox

          # Get all conversation messages and let the unified method handle filtering
          conversation_messages = message.conversation_messages

          # Use the unified method with inbox filtering (much more efficient)
          Messages::Operations::ActionsService.mark_messages_as_read(
            conversation_messages,
            inbox_filter: current_user.inbox
          )
        end

        def prepare_new_message(parent_message_id, current_user)
          message = Message.new(parent_message_id: parent_message_id)
          message.outbox = current_user.outbox if current_user&.outbox
          message.routing_type = :reply if message.parent_message_id.present?
          message
        end

        def determine_recipient_for_message(message, current_user)
          return nil if message.parent_message_id.present?

          begin
            routing_service = Messages::Operations::RoutingService.new(message, current_user)
            routing_service.determine_recipient
          rescue Messages::Operations::RoutingService::NoDoctorAvailableError,
                 Messages::Operations::RoutingService::NoAdminAvailableError,
                 Messages::Operations::RoutingService::NoPatientAvailableError,
                 Messages::Operations::RoutingService::UnsupportedUserRoleError
            nil
          end
        end

        # Mark a single message as read when viewing individual message
        def mark_message_as_read(message)
          return if message.read_already?

          # Use the unified method for consistency
          Messages::Operations::ActionsService.mark_messages_as_read([message])
        end
      end
    end
  end
end
