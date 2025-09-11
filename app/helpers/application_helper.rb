# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend # Add Pagy frontend helpers for pagination views
  include Shared::UserPresentation # Shared user presentation logic

  # Check if a message is a prescription request message
  def prescription_request_message?(message)
    # Use database relationship - much cleaner and more reliable
    message.prescription_id.present? &&
      message.prescription&.payment&.completed?
  end

  # Check if a message is a prescription ready message (contains PDF link)
  def prescription_ready_message?(message)
    return false if message.body.blank?

    message.body.include?('prescription is ready') &&
      message.body.include?('<a href=')
  end

  # Find the prescription associated with a message - now trivial with DB relationship
  def find_prescription_from_message(message)
    message.prescription
  end
end
