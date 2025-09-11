# frozen_string_literal: true

module Messages
  module Operations
    # Manages message CRUD operations in medical communication workflow.
    # Handles status updates, validation, and bulk operations with business rule enforcement.
    class ActionsService
      class << self
        # == Status Update Operations ==

        # Mark message as read (safe) - returns false for invalid transitions
        def mark_as_read(message)
          return false unless can_mark_as_read?(message)

          update_attributes = { status: :read, read: true, read_at: Time.current }
          message.update(update_attributes)
        end

        # Mark message as read (force) - raises error for invalid transitions
        def mark_as_read!(message)
          validate_can_mark_as_read!(message)

          update_attributes = { status: :read, read: true, read_at: Time.current }
          message.update!(update_attributes)
        end

        # Mark message as delivered (safe) - returns false for invalid transitions
        def mark_as_delivered(message)
          return false unless can_mark_as_delivered?(message)

          message.update(status: :delivered)
        end

        # Mark message as delivered (force) - raises error for invalid transitions
        def mark_as_delivered!(message)
          validate_can_mark_as_delivered!(message)

          message.update!(status: :delivered)
        end

        # == Bulk Operations ==

        # Unified method for marking messages as read (single or multiple)
        # Handles unread count updates and broadcasting efficiently
        # @param messages [Array<Message>] Messages to mark as read (can be objects or IDs)
        # @param inbox_filter [Inbox, nil] Optional inbox to filter messages (for conversation reads)
        def mark_messages_as_read(messages, inbox_filter: nil)
          message_ids = Array(messages).map { |msg| msg.respond_to?(:id) ? msg.id : msg }
          return { updated_count: 0, affected_inboxes: [] } if message_ids.empty?

          # Build query for messages that can transition to read
          query = Message.includes(:inbox)
                         .where(id: message_ids)
                         .where.not(status: :read)
                         .where(status: %i[sent delivered])

          # Add inbox filter for conversation reads (more efficient than Ruby filtering)
          query = query.where(inbox: inbox_filter) if inbox_filter

          # Check if we have any valid messages before proceeding
          return { updated_count: 0, affected_inboxes: [] } if query.none?

          # Load messages for grouping by inbox (after we know there are some)
          valid_messages = query.to_a
          messages_by_inbox = valid_messages.group_by(&:inbox)

          # Perform bulk update using the original query relation
          updated_count = query.update_all(
            status: :read,
            read: true,
            read_at: Time.current,
            updated_at: Time.current
          )

          affected_inboxes = []

          # Update unread counts and broadcast for each affected inbox
          messages_by_inbox.each do |inbox, inbox_messages|
            next unless inbox

            # Update inbox unread count immediately
            count_decrease = inbox_messages.count
            new_count = [inbox.unread_count - count_decrease, 0].max
            inbox.update!(unread_count: new_count)

            # Update cache and broadcast immediately
            ::Caching::UnreadCountService.set_unread_count(inbox, new_count)
            ::Broadcasting::InboxUpdatesService.broadcast_unread_count_update(inbox)

            affected_inboxes << inbox

            # Broadcast individual message updates for UI consistency
            inbox_messages.each do |msg|
              msg.reload # Ensure message has updated attributes
              ::Broadcasting::MessageStatusService.broadcast_status_update(msg)
            end
          end

          { updated_count: updated_count, affected_inboxes: affected_inboxes }
        end

        # Legacy method for backward compatibility
        def bulk_mark_as_read(messages)
          result = mark_messages_as_read(messages)
          result[:updated_count]
        end

        # Bulk delivery confirmation - validates transitions before update
        def bulk_mark_as_delivered(messages)
          message_ids = Array(messages).map(&:id)
          return 0 if message_ids.empty?

          # Only process sent messages (can transition to delivered)
          valid_messages = Message.where(id: message_ids)
                                  .where(status: :sent)

          return 0 if valid_messages.empty?

          valid_messages.update_all(status: :delivered, updated_at: Time.current)
        end

        private

        # == Validation Helpers ==

        # Check if message can be marked as read
        def can_mark_as_read?(message)
          Messages::Operations::StatusService.new(message).can_transition_to?(:read)
        end

        # Check if message can be marked as delivered
        def can_mark_as_delivered?(message)
          Messages::Operations::StatusService.new(message).can_transition_to?(:delivered)
        end

        # Validate read transition (with error)
        def validate_can_mark_as_read!(message)
          return if can_mark_as_read?(message)

          raise ArgumentError, "Cannot mark message as read: invalid status transition from #{message.status}"
        end

        # Validate delivery transition (with error)
        def validate_can_mark_as_delivered!(message)
          return if can_mark_as_delivered?(message)

          raise ArgumentError, "Cannot mark message as delivered: invalid status transition from #{message.status}"
        end
      end
    end
  end
end
