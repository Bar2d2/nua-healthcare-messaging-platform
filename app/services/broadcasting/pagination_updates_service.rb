# frozen_string_literal: true

module Broadcasting
  # Handles real-time pagination updates when new items are added to lists.
  # Updates pagination info and navigation when items are added via broadcasting.
  class PaginationUpdatesService
    class << self
      # Broadcast updated pagination for messages (inbox/outbox)
      def broadcast_message_pagination_update(user, list_type = :inbox)
        return unless user

        # Recalculate pagination for current page
        messages = case list_type
                   when :inbox
                     user.inbox.messages.includes(:outbox).recent
                   when :outbox
                     user.outbox.messages.includes(:inbox).recent
                   else
                     return
                   end

        # Get pagination info
        pagy, = Pagy.new(count: messages.count, items: 10, page: 1)

        # Broadcast pagination info update
        stream_name = if list_type == :inbox
                        Broadcasting::TurboStreamsService.inbox_stream(user.inbox)
                      else
                        Broadcasting::TurboStreamsService.outbox_stream(user)
                      end

        target_id = "#{list_type}-pagination-info"

        Broadcasting::TurboStreamsService.broadcast_update_to(
          stream_name,
          target: target_id,
          partial: 'shared/pagination_info',
          locals: { pagy: pagy }
        )

        # Broadcast pagination nav if needed
        return unless pagy.pages > 1

        Broadcasting::TurboStreamsService.broadcast_update_to(
          stream_name,
          target: "#{list_type}-pagination-nav",
          partial: 'shared/pagination_nav',
          locals: { pagy: pagy }
        )
      end

      # Broadcast updated pagination for prescriptions
      def broadcast_prescription_pagination_update(user)
        return unless user&.is_patient?

        prescriptions = user.prescriptions.recent
        pagy, = Pagy.new(count: prescriptions.count, items: 10, page: 1)

        stream_name = "user_#{user.id}_prescriptions"

        # Broadcast pagination info
        Broadcasting::TurboStreamsService.broadcast_update_to(
          stream_name,
          target: 'prescriptions-pagination-info',
          partial: 'shared/pagination_info',
          locals: { pagy: pagy }
        )

        # Broadcast pagination nav if needed
        return unless pagy.pages > 1

        Broadcasting::TurboStreamsService.broadcast_update_to(
          stream_name,
          target: 'prescriptions-pagination-nav',
          partial: 'shared/pagination_nav',
          locals: { pagy: pagy }
        )
      end

      # Enqueue pagination update job (for performance)
      def enqueue_message_pagination_update(user, list_type = :inbox)
        PaginationUpdateJob.perform_later(user.id, 'message', list_type.to_s)
      end

      # Enqueue prescription pagination update job
      def enqueue_prescription_pagination_update(user)
        PaginationUpdateJob.perform_later(user.id, 'prescription', nil)
      end
    end
  end
end
