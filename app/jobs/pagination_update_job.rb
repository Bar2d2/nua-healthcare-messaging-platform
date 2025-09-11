# frozen_string_literal: true

# Background job for updating pagination info when new items are added to lists.
# Handles both message and prescription pagination updates for performance.
class PaginationUpdateJob < ApplicationJob
  queue_as :default

  def perform(user_id, update_type, list_type = nil)
    user = User.find_by(id: user_id)
    return unless user

    case update_type
    when 'message'
      Broadcasting::PaginationUpdatesService.broadcast_message_pagination_update(user, list_type&.to_sym || :inbox)
    when 'prescription'
      Broadcasting::PaginationUpdatesService.broadcast_prescription_pagination_update(user)
    end

    Rails.logger.info "Updated pagination for user #{user_id}, type: #{update_type}, list: #{list_type}"
  rescue StandardError => e
    Rails.logger.error "Pagination update failed for user #{user_id}: #{e.message}"
  end
end
