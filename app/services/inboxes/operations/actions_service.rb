# frozen_string_literal: true

module Inboxes
  module Operations
    # Manages inbox operations including unread count management and bulk actions
    # Coordinates database updates, caching, and broadcasting for inbox state changes
    class ActionsService
      attr_reader :inbox

      def initialize(inbox)
        @inbox = inbox
      end

      # == Unread Count Operations ==

      # Increment unread count (when new message arrives)
      def increment!
        inbox.increment!(:unread_count)
        Caching::UnreadCountService.increment_unread_count(inbox)
        Broadcasting::InboxUpdatesService.broadcast_unread_count_update(inbox)
      end

      # Decrement unread count (when message is read)
      def decrement!
        inbox.decrement!(:unread_count) if inbox.unread_count.positive?
        Caching::UnreadCountService.decrement_unread_count(inbox)
        Broadcasting::InboxUpdatesService.broadcast_unread_count_update(inbox)
      end

      # Reset unread count to zero
      def reset!
        inbox.update!(unread_count: 0)
        Caching::UnreadCountService.reset_unread_count(inbox)
        Broadcasting::InboxUpdatesService.broadcast_unread_count_update(inbox)
      end

      # Set unread count to specific value
      def set!(count)
        normalized_count = [count, 0].max
        inbox.update!(unread_count: normalized_count)
        Caching::UnreadCountService.set_unread_count(inbox, normalized_count)
        Broadcasting::InboxUpdatesService.broadcast_unread_count_update(inbox)
      end

      # Recalculate unread count from actual messages
      def recalculate!
        # Count all unread messages including replies - users need to know about new replies
        actual_count = inbox.messages.unread.count
        set!(actual_count)
      end

      # == Bulk Actions ==

      # Mark all messages as read
      def mark_all_as_read!
        # Update all unread messages
        inbox.messages.unread.update_all(read: true, status: :read, read_at: Time.current)

        # Recalculate cache since update_all doesn't trigger callbacks
        # Note: recalculate! automatically handles both unread count and button broadcasting
        recalculate!
      end

      # == Class Methods ==

      class << self
        # Convenience methods for one-off operations
        def increment!(inbox)
          new(inbox).increment!
        end

        def decrement!(inbox)
          new(inbox).decrement!
        end

        def reset!(inbox)
          new(inbox).reset!
        end

        def set!(inbox, count)
          new(inbox).set!(count)
        end

        def recalculate!(inbox)
          new(inbox).recalculate!
        end

        def mark_all_as_read!(inbox)
          new(inbox).mark_all_as_read!
        end
      end
    end
  end
end
