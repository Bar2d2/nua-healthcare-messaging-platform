# frozen_string_literal: true

# Background job for broadcasting prescription updates via Turbo Streams
# Batches multiple prescription broadcasts for optimal performance
class BroadcastPrescriptionUpdateJob < ApplicationJob
  queue_as :high_priority

  # Broadcast prescription status updates to all relevant streams in logical order
  # @param prescription_id [String] The ID of the prescription to broadcast
  # @param notification_message [String, nil] Optional notification message
  # @param wait_for_message_creation [Boolean] Whether to wait for related message creation
  def perform(prescription_id, notification_message = nil, wait_for_message_creation: false)
    prescription = Prescription.find_by(id: prescription_id)
    return unless prescription&.user

    Rails.logger.info "Broadcasting prescription update #{prescription_id} in background"

    # If we need to wait for message creation (e.g., prescription ready message)
    if wait_for_message_creation
      # Small delay to ensure message creation job completes first
      sleep(0.5)
      Rails.logger.info "Waited for message creation before broadcasting prescription #{prescription_id}"
    end

    # Batch all prescription-related broadcasts in LOGICAL ORDER
    user = prescription.user

    # 1. FIRST: Update prescription item in patient list (most important)
    broadcast_prescription_item_update(prescription)

    # 2. SECOND: Update action button and badge in admin conversation view (admin visibility)
    broadcast_prescription_action_button_update(prescription)

    # 3. THIRD: Update prescription count badge (auxiliary info)
    broadcast_prescription_count_update(user)

    # 4. FOURTH: Show notification if provided (last, so user sees updated state)
    broadcast_notification(user, notification_message) if notification_message

    # 5. FINALLY: Enqueue pagination update (after all content updates)
    Broadcasting::PaginationUpdatesService.enqueue_prescription_pagination_update(user)

    Rails.logger.info "Successfully broadcast prescription update #{prescription_id} in logical order"
  rescue StandardError => e
    Rails.logger.error "Failed to broadcast prescription update #{prescription_id}: #{e.message}"
    # Re-raise to trigger retry mechanism
    raise e
  end

  private

  # Delegate to the service methods for consistency
  def broadcast_prescription_item_update(prescription)
    Broadcasting::PrescriptionUpdatesService.send(:broadcast_prescription_item_update, prescription)
  end

  def broadcast_prescription_action_button_update(prescription)
    Broadcasting::PrescriptionUpdatesService.send(:broadcast_prescription_action_button_update, prescription)
  end

  def broadcast_notification(user, message)
    Broadcasting::PrescriptionUpdatesService.send(:broadcast_notification, user, message)
  end

  def broadcast_prescription_count_update(user)
    Broadcasting::PrescriptionUpdatesService.send(:broadcast_prescription_count_update, user)
  end
end
