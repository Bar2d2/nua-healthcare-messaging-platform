# frozen_string_literal: true

# Background job for fake prescription generation with delay.
# Simulates admin prescription generation process for demonstration.
class PrescriptionGenerationJob < ApplicationJob
  queue_as :default

  # Generate fake prescription after 3-second delay
  # @param prescription_id [String] The ID of the prescription to generate
  # @param message_id [String, nil] Optional original message ID for reply
  def perform(prescription_id, message_id = nil)
    prescription = Prescription.find_by(id: prescription_id)
    return unless prescription

    logger.info "Generating fake prescription for #{prescription_id}"

    # Generate fake PDF URL
    pdf_url = "https://example.com/prescriptions/#{prescription.id}.pdf"
    prescription.mark_as_ready!(pdf_url)

    # Send reply to patient with prescription link (this creates a message)
    send_prescription_to_patient(prescription, message_id)

    # IMPORTANT: Broadcast AFTER message creation with wait to ensure proper order
    Broadcasting::PrescriptionUpdatesService.broadcast_status_update(
      prescription,
      nil, # No notification message to prevent duplicate flash
      wait_for_message: true # Wait for message creation job to complete
    )

    logger.info "Successfully generated prescription #{prescription_id}"
  end

  private

  # Send prescription download link to patient
  def send_prescription_to_patient(prescription, original_message_id)
    admin = User.admin.first
    return unless admin

    reply_body = "Your prescription is ready! \n" \
                 "Download your prescription: <a href=\"#{prescription.pdf_url}\" target=\"_blank\">Download Prescription</a>\n\n" \

    message_params = {
      body: reply_body,
      status: 'sent'
    }

    # If we have original message, make it a reply
    if original_message_id
      message_params[:routing_type] = 'reply'
      message_params[:parent_message_id] = original_message_id
    else
      message_params[:routing_type] = 'direct'
    end

    # Create message from admin to patient
    MessageCreationJob.perform_later(
      message_params,
      admin.id,
      nil
    )
  end
end
