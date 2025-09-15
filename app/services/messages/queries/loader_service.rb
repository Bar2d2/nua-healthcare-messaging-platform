# frozen_string_literal: true

module Messages
  module Queries
    # Simple message loading service for controllers.
    # Returns properly configured ActiveRecord relations for pagination.
    class LoaderService
      class << self
        # Get inbox messages relation ready for pagination (optimized for conversation data)
        def inbox_messages_for_user(user)
          user.inbox.messages
              .includes(:outbox, :parent_message, :prescription,
                        outbox: :user, inbox: :user,
                        parent_message: %i[inbox outbox],
                        prescription: :payment) # Preload prescription and payment data
              .order(created_at: :desc) # Use optimized index
              .limit(10) # Limit to reduce query size
        end

        # Get outbox messages relation ready for pagination (optimized for conversation data)
        def outbox_messages_for_user(user)
          user.outbox.messages
              .includes(:inbox, :parent_message, :prescription,
                        inbox: :user, outbox: :user,
                        parent_message: %i[inbox outbox],
                        prescription: :payment) # Preload prescription and payment data
              .order(created_at: :desc) # Use optimized index
              .limit(10) # Limit to reduce query size
        end

        # Safely find a message by ID with error handling (optimized with includes)
        def find_message_safely(message_id)
          Message.includes(:inbox, :outbox, :parent_message, :replies, :prescription,
                           inbox: :user, outbox: :user,
                           parent_message: %i[inbox outbox],
                           replies: %i[inbox outbox],
                           prescription: :payment)
                 .find(message_id)
        rescue ActiveRecord::RecordNotFound
          nil
        end
      end
    end
  end
end
