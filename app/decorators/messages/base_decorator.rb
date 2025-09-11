# frozen_string_literal: true

module Messages
  # Main decorator for Message model providing conversation-related functionality.
  # Follows the Decorator pattern to add behavior without modifying the core model.
  # Implements rich conversation interface for medical communication display.
  class BaseDecorator < SimpleDelegator
    include Messages::ConversationDecorator
    include Messages::DataDecorator
    include Messages::ViewDecorator
    include Messages::NavigationDecorator

    def initialize(message)
      super
      @message = message
    end

    # == Delegated Behavior ==

    # Delegates routing type predicates to the underlying message's value object.
    delegate :routing_type_object, :reply?, :direct?, :auto?, to: :@message

    # == Factory Methods ==

    class << self
      # Create decorator instance for a single message.
      def decorate(message)
        new(message)
      end

      # Decorates a collection of messages for batch operations.
      def decorate_collection(messages)
        messages.map { |message| decorate(message) }
      end
    end
  end
end
