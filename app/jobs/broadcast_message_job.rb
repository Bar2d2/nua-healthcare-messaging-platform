# frozen_string_literal: true

# Background job for broadcasting new messages via Turbo Streams
# Decouples message creation from broadcasting to improve performance
class BroadcastMessageJob < ApplicationJob
  queue_as :high_priority

  # Broadcast a new message to relevant streams
  # @param message_id [String] The ID of the message to broadcast
  def perform(message_id)
    message = Message.find_by(id: message_id)
    return unless message

    Rails.logger.info "Broadcasting new message #{message.id} in background"

    # Use the new global broadcasting service
    Broadcasting::MessageDeliveryService.broadcast_new_message(message)

    Rails.logger.info "Successfully broadcast new message #{message.id}"
  rescue StandardError => e
    Rails.logger.error "Failed to broadcast message #{message_id}: #{e.message}"
    # Re-raise to trigger retry mechanism
    raise e
  end
end
