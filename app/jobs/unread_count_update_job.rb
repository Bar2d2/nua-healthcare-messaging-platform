# frozen_string_literal: true

# Background job for updating unread counts to improve message creation performance
# Handles unread count increments/decrements without blocking message creation
class UnreadCountUpdateJob < ApplicationJob
  queue_as :default # Lower priority than broadcasting

  # Update unread count for a specific inbox
  # @param inbox_id [String] The ID of the inbox to update
  # @param operation [String] The operation to perform: 'increment', 'decrement', 'reset'
  # @param count [Integer] The count to set (for 'set' operation)
  def perform(inbox_id, operation, count = nil)
    inbox = Inbox.find_by(id: inbox_id)
    return unless inbox

    logger.info "Updating unread count for inbox #{inbox_id}: #{operation}"

    execute_operation(inbox, operation, count)

    logger.info "Successfully updated unread count for inbox #{inbox_id}"
  rescue StandardError => e
    logger.error "Failed to update unread count for inbox #{inbox_id}: #{e.message}"
    # Don't re-raise to avoid retries for now
  end

  private

  def execute_operation(inbox, operation, count)
    case operation.to_s
    when 'increment'
      Inboxes::Operations::ActionsService.increment!(inbox)
    when 'decrement'
      Inboxes::Operations::ActionsService.decrement!(inbox)
    when 'reset'
      Inboxes::Operations::ActionsService.reset!(inbox)
    when 'set'
      Inboxes::Operations::ActionsService.set!(inbox, count || 0)
    when 'recalculate'
      Inboxes::Operations::ActionsService.recalculate!(inbox)
    else
      logger.error "Unknown unread count operation: #{operation}"
    end
  end
end
