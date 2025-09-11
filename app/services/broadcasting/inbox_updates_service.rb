# frozen_string_literal: true

module Broadcasting
  # Handles inbox-specific broadcasting: unread counts and mark all read buttons
  # Consolidates all inbox UI update logic in one place
  class InboxUpdatesService
    class << self
      # == Unread Count Broadcasting ==

      # Broadcast unread count update to user's inbox stream
      def broadcast_unread_count_update(inbox)
        return unless inbox&.user

        Broadcasting::TurboStreamsService.broadcast_update_to(
          Broadcasting::TurboStreamsService.inbox_stream(inbox),
          target: "inbox_unread_count_#{inbox.id}",
          partial: 'inboxes/unread_count',
          locals: { inbox: inbox }
        )

        # Automatically update mark all read button visibility
        broadcast_mark_all_read_button_update(inbox.user)
      end

      # Broadcast unread count update with specific count (for real-time updates)
      def broadcast_unread_count_update_with_count(user, count)
        return unless user&.inbox

        Broadcasting::TurboStreamsService.broadcast_update_to(
          Broadcasting::TurboStreamsService.inbox_stream(user.inbox),
          target: "inbox_unread_count_#{user.inbox.id}",
          partial: 'inboxes/unread_count',
          locals: { inbox: user.inbox, unread_count: count }
        )
      end

      # == Mark All Read Button Broadcasting ==

      # Broadcast mark all read button visibility update
      def broadcast_mark_all_read_button_update(user)
        return unless user&.inbox

        Broadcasting::TurboStreamsService.broadcast_update_to(
          Broadcasting::TurboStreamsService.inbox_stream(user.inbox),
          target: 'mark_all_read_button',
          partial: 'messages/partials/mark_all_read_button',
          locals: { inbox: user.inbox }
        )
      end
    end
  end
end
