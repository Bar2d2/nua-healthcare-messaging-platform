# frozen_string_literal: true

module Messages
  module Conversations
    # Manages conversation threading and participant identification.
    # Handles conversation analytics and message collection for medical communications.
    class DataService
      attr_reader :message

      def initialize(message)
        @message = message
      end

      # == Public Interface ==

      # Get conversation root message (first message in thread)
      def root
        find_conversation_root
      end

      # Get conversation owner (sender of root message)
      def owner
        root.outbox.user
      end

      # Get all messages in conversation thread
      def messages
        collect_conversation_messages
      end

      # Get all participants in conversation
      def participants
        @participants ||= Messages::Participants::DataService.new(messages).all_participants
      end

      # Get doctor participant in conversation
      def doctor
        @doctor ||= Messages::Participants::DataService.new(messages).find_doctor_in_conversation
      end

      # Check if conversation has multiple messages (threaded)
      def threaded?
        messages.many?
      end

      # Get conversation participants (alias for participants)
      def conversation_participants
        participants
      end

      # Get conversation owner (alias for owner)
      def conversation_owner
        owner
      end

      # == Analytics ==

      # Get conversation statistics and metrics
      def stats
        {
          message_count: messages.count,
          participant_count: participants.count,
          has_doctor: doctor.present?,
          is_threaded: threaded?,
          created_at: root.created_at,
          last_activity: messages.maximum(:created_at)
        }
      end

      private

      # Find the root message of the conversation thread (optimized)
      def find_conversation_root
        @find_conversation_root ||= find_conversation_root_optimized
      end

      # Optimized root finding using ActiveRecord query
      def find_conversation_root_optimized
        # If message has no parent, it IS the root
        return message if message.parent_message_id.nil?

        # Use ActiveRecord to find the root message efficiently
        # Start from current message and follow parent_message_id chain
        current_message = message
        max_depth = 10 # Prevent infinite loops
        depth = 0

        while current_message.parent_message_id.present? && depth < max_depth
          parent = Message.includes(:parent_message, :inbox, :outbox)
                          .find_by(id: current_message.parent_message_id)
          break unless parent

          current_message = parent
          depth += 1
        end

        current_message
      end

      # Collect all messages in conversation thread
      def collect_conversation_messages
        @collect_conversation_messages ||= load_conversation_messages_optimized
      end

      # Optimized conversation loading using ActiveRecord only
      def load_conversation_messages_optimized
        root_message = root

        # Load all messages that share the same conversation root
        conversation_messages = load_conversation_by_root(root_message.id)

        # Sort by creation time for proper conversation flow (newest first)
        conversation_messages.sort_by(&:created_at).reverse
      end

      # Load entire conversation using ActiveRecord queries
      def load_conversation_by_root(root_id)
        # Use iterative approach to find all conversation messages
        all_message_ids = collect_conversation_ids_iteratively(root_id)

        # Single query to load all conversation messages with associations
        Message.where(id: all_message_ids)
               .includes(:inbox, :outbox, :parent_message,
                         inbox: :user, outbox: :user,
                         replies: %i[inbox outbox])
               .to_a # Force loading to avoid lazy evaluation
      end

      # Collect all message IDs in conversation using breadth-first traversal
      def collect_conversation_ids_iteratively(root_id)
        all_ids = [root_id]
        current_level = [root_id]
        max_depth = 20 # Safety limit for very deep conversations
        depth = 0

        while current_level.any? && depth < max_depth
          # Get all direct replies to current level messages in single query
          next_level = Message.where(parent_message_id: current_level).pluck(:id)
          break if next_level.empty?

          all_ids.concat(next_level)
          current_level = next_level
          depth += 1
        end

        all_ids.uniq
      end

      # Find all participants in conversation
      def find_participants
        Messages::Participants::ExtractorService.from_messages(messages)
      end
    end
  end
end
