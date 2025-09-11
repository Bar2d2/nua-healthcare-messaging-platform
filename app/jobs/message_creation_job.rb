# frozen_string_literal: true

# Background job for message creation to maximize throughput
# Handles message creation, routing, and delivery asynchronously
class MessageCreationJob < ApplicationJob
  queue_as :high_priority # High priority for user-initiated actions

  # Create and send a message in the background
  # @param message_attributes [Hash] The validated message attributes
  # @param request_user_id [String] The ID of the user sending the message
  # @param session_id [String] Optional session ID for response tracking
  def perform(message_attributes, request_user_id, session_id = nil)
    request_user = User.find_by(id: request_user_id)
    return unless request_user

    Rails.logger.info "Creating message in background for user #{request_user_id}"

    # Create message params object (validation already done in controller)
    message_params = MessageParams.new(message_attributes.merge(request_user: request_user))

    # Use existing SendService for message creation and routing
    send_service = Messages::Operations::SendService.new(message_params, request_user)
    result = send_service.call

    if result.success?
      Rails.logger.info "Successfully created message #{result.data.id} in background"

      # Broadcast success notification to user (optional)
      broadcast_creation_success(request_user, result.data, session_id)
    else
      Rails.logger.error "Failed to create message in background: #{result.error_message}"

      # Broadcast error notification to user (optional)
      broadcast_creation_error(request_user, result.error_message, session_id)
    end

    result
  rescue StandardError => e
    Rails.logger.error "Message creation job failed for user #{request_user_id}: #{e.message}"

    # Broadcast error notification
    broadcast_creation_error(request_user, e.message, session_id) if request_user

    # Re-raise to trigger retry mechanism
    raise e
  end

  private

  # Broadcast success notification to user
  def broadcast_creation_success(user, message, session_id)
    # Optional: Broadcast success message to user's stream
    # This could show a toast notification or redirect
  end

  # Broadcast error notification to user
  def broadcast_creation_error(user, error_message, session_id)
    # Optional: Broadcast error message to user's stream
    # This could show an error toast or form errors
  end
end
