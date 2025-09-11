# frozen_string_literal: true

# Background job for broadcasting message updates via Turbo Streams
# Handles read status changes and other message updates
class BroadcastUpdateJob < ApplicationJob
  queue_as :high_priority

  # Broadcast a message update to relevant streams
  # @param message_id [String] The ID of the message to broadcast
  def perform(message_id)
    message = Message.find_by(id: message_id)
    return unless message

    Rails.logger.info "Broadcasting message update #{message.id} in background"

    # Use the new global broadcasting service
    Broadcasting::MessageStatusService.broadcast_status_update(message)

    Rails.logger.info "Successfully broadcast message update #{message.id}"
  rescue StandardError => e
    Rails.logger.error "Failed to broadcast message update #{message_id}: #{e.message}"
    # Re-raise to trigger retry mechanism
    raise e
  end
end
