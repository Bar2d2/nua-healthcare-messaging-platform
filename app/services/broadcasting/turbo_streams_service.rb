# frozen_string_literal: true

module Broadcasting
  # Core Turbo Streams broadcasting service
  # Provides common broadcasting methods with consistent stream naming
  class TurboStreamsService
    class << self
      # == Core Broadcasting Methods ==

      def broadcast_append_to(stream, target:, partial:, locals: {})
        Turbo::StreamsChannel.broadcast_append_to(stream, target: target, partial: partial, locals: locals)
      end

      def broadcast_prepend_to(stream, target:, partial:, locals: {})
        Turbo::StreamsChannel.broadcast_prepend_to(stream, target: target, partial: partial, locals: locals)
      end

      def broadcast_replace_to(stream, target:, partial:, locals: {})
        Turbo::StreamsChannel.broadcast_replace_to(stream, target: target, partial: partial, locals: locals)
      end

      def broadcast_update_to(stream, target:, partial:, locals: {})
        Turbo::StreamsChannel.broadcast_update_to(stream, target: target, partial: partial, locals: locals)
      end

      def broadcast_remove_to(stream, target:)
        Turbo::StreamsChannel.broadcast_remove_to(stream, target: target)
      end

      # == Stream Naming Conventions ==
      # Consistent stream names across the application

      def inbox_stream(inbox)
        "inbox_#{inbox.id}"
      end

      def outbox_stream(user)
        "user_#{user.id}_outbox"
      end

      def conversation_stream(conversation_root)
        "conversation_#{conversation_root.id}"
      end

      def messages_stream
        'messages'
      end
    end
  end
end
