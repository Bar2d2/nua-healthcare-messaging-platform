# frozen_string_literal: true

# Background job for broadcasting new prescription additions via Turbo Streams
# Handles prescription list updates and pagination when new prescriptions are created
class BroadcastPrescriptionAddedJob < ApplicationJob
  queue_as :high_priority

  # Broadcast new prescription addition to patient's prescription list
  # @param prescription_id [String] The ID of the prescription to broadcast
  def perform(prescription_id)
    prescription = Prescription.find_by(id: prescription_id)
    return unless prescription&.user

    Rails.logger.info "Broadcasting prescription addition #{prescription_id} in background"

    # Use the synchronous method for actual broadcasting logic
    Broadcasting::PrescriptionUpdatesService.broadcast_prescription_added_sync(prescription)

    Rails.logger.info "Successfully broadcast prescription addition #{prescription_id}"
  rescue StandardError => e
    Rails.logger.error "Failed to broadcast prescription addition #{prescription_id}: #{e.message}"
    # Re-raise to trigger retry mechanism
    raise e
  end
end
