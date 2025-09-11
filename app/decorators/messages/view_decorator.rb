# frozen_string_literal: true

module Messages
  # Handles view rendering and HTML generation for message decorators.
  # Provides methods for generating HTML output for messages and conversations.
  module ViewDecorator
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::DateHelper
    include ActionView::Helpers::OutputSafetyHelper
    include Shared::UserPresentation

    # == HTML Presentation Methods ==

    # Renders complete conversation history for doctor view with proper HTML structure.
    def conversation_history_html
      return '' unless respond_to?(:content_tag) # Ensure view context is available

      conversation_messages = self.conversation_messages

      content_tag(:div, class: 'conversation-history') do
        safe_join([
                    content_tag(:h6, 'Conversation History', class: 'mb-3'),
                    *conversation_messages.map { |msg| Messages::BaseDecorator.decorate(msg).conversation_message_html }
                  ])
      end
    end

    # Renders individual conversation message with proper styling and structure.
    def conversation_message_html
      return '' unless respond_to?(:content_tag) # Ensure view context is available

      sender = sender_user
      message_class = sender.is_doctor? ? 'doctor-message' : 'patient-message'

      content_tag(:div, class: "message #{message_class} mb-2") do
        message_header_html + message_body_html
      end
    end

    # Renders message header with sender name and timestamp.
    def message_header_html
      return '' unless respond_to?(:content_tag) # Ensure view context is available

      sender = sender_user

      content_tag(:div, class: 'message-header') do
        content_tag(:strong, sender.full_name) +
          content_tag(:small, " - #{time_ago_in_words(created_at)} ago", class: 'text-muted ms-2')
      end
    end

    # Renders message body with proper HTML structure.
    def message_body_html
      return '' unless respond_to?(:content_tag) # Ensure view context is available

      content_tag(:div, class: 'message-body mt-1') do
        content_tag(:p, body, class: 'mb-0')
      end
    end

    # == Role Icon Methods ==

    # Get icon for the message sender's role.
    def sender_role_icon
      role_icon(sender_user.role)
    end

    # Get icon for the message recipient's role.
    def recipient_role_icon
      role_icon(recipient_user.role)
    end
  end
end
