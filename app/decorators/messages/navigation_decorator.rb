# frozen_string_literal: true

module Messages
  # Handles navigation state and UI context for message decorators.
  # Provides methods for determining active navigation states and user context.
  module NavigationDecorator
    # == Navigation State Methods ==

    # Enhanced navigation methods that replace NavigationHelper functionality
    # Determines if inbox navigation should be active based on message context
    def inbox_active?(current_user = nil, request = nil)
      current_user ||= User.current

      # Check if we're on inbox path
      return true if request&.path == '/inbox'

      # Check if viewing this message as a received message
      viewing_received_message?(current_user) && viewing_message_page?(request)
    end

    # Determines if outbox navigation should be active based on message context
    def outbox_active?(current_user = nil, request = nil)
      current_user ||= User.current

      # Check if we're on outbox path
      return true if request&.path == '/outbox'

      # Check if viewing this message as a sent message
      viewing_sent_message?(current_user) && viewing_message_page?(request)
    end

    # Get comprehensive navigation context for this message
    def navigation_context(current_user = nil, request = nil)
      current_user ||= User.current
      return { inbox: false, outbox: false } unless current_user

      {
        inbox: inbox_active?(current_user, request),
        outbox: outbox_active?(current_user, request)
      }
    end

    private

    # Check if current user is viewing this message as a received message.
    def viewing_received_message?(current_user)
      # Message is received if current user is the inbox owner and not the sender
      inbox&.user == current_user && outbox&.user != current_user
    end

    # Check if current user is viewing this message as a sent message.
    def viewing_sent_message?(current_user)
      # Message is sent if current user is the outbox owner and not the recipient
      outbox&.user == current_user && inbox&.user != current_user
    end

    # Check if we're currently viewing a message show page.
    def viewing_message_page?(request)
      return false unless request

      # Check controller and action from request path or params
      request.path.include?('/messages/') && !request.path.end_with?('/new')
    end
  end
end
