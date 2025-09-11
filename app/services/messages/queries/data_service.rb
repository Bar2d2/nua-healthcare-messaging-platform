# frozen_string_literal: true

module Messages
  module Queries
    # Simple read-only query operations for the medical messaging system.
    # Implements Command/Query Separation (CQS) pattern with minimal, focused methods.
    class DataService
      class << self
        # Get paginated messages for inbox/outbox
        def paginated_user_messages(user_id, box_type:, page: 1, per_page: 10)
          user = User.find(user_id)

          case box_type.to_sym
          when :inbox
            Message.where(inbox_id: user.inbox.id)
          when :outbox
            Message.where(outbox_id: user.outbox.id)
          else
            raise ArgumentError, "Invalid box_type: #{box_type}. Must be :inbox or :outbox"
          end
            .includes(:outbox, :parent_message, outbox: :user)
            .order(created_at: :desc)
            .offset((page - 1) * per_page)
            .limit(per_page)
        end

        # Get unread counts for multiple users (batch operation)
        def unread_counts_by_user(user_ids)
          User.where(id: user_ids)
              .includes(:inbox)
              .to_h { |user| [user.id, user.inbox&.unread_count || 0] }
        end
      end
    end
  end
end
