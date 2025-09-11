# frozen_string_literal: true

# Background job for marking all messages as read to prevent blocking UI
# Handles bulk read operations for inboxes with many messages
class MarkAllReadJob < ApplicationJob
  queue_as :default # Medium priority

  # Mark all messages as read for a specific inbox (with batching)
  # @param inbox_id [String] The ID of the inbox to process
  # @param user_id [String] The ID of the user (for broadcasting)
  def perform(inbox_id, user_id)
    inbox = Inbox.find_by(id: inbox_id)
    user = User.find_by(id: user_id)

    return unless inbox && user

    Rails.logger.info "Marking all messages as read for inbox #{inbox_id}"

    # Process messages in batches (newest to oldest for better UX)
    batch_size = 50
    total_updated = 0

    loop do
      # Get next batch of unread messages (newest first)
      unread_messages = inbox.messages.unread
                             .order(created_at: :desc)
                             .limit(batch_size)

      break if unread_messages.empty?

      # Update batch efficiently
      updated_count = unread_messages.update_all(
        read: true,
        status: :read,
        read_at: Time.current,
        updated_at: Time.current
      )

      total_updated += updated_count

      # Broadcast progress update after each batch
      remaining_count = inbox.messages.unread.count
      inbox.update!(unread_count: remaining_count)

      # Update cache and broadcast
      Caching::UnreadCountService.set_unread_count(inbox, remaining_count)
      Broadcasting::InboxUpdatesService.broadcast_unread_count_update(inbox)

      # Small delay between batches to prevent database overload
      sleep(0.1)

      break if remaining_count.zero?
    end

    Rails.logger.info "Successfully marked #{total_updated} messages as read for inbox #{inbox_id}"
  rescue StandardError => e
    Rails.logger.error "Failed to mark all messages as read for inbox #{inbox_id}: #{e.message}"
    # Re-raise to trigger retry mechanism for critical operation
    raise e
  end
end
