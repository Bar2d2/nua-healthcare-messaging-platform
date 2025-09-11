# frozen_string_literal: true

# Query object for Message model following the Query Object pattern.
# Encapsulates all complex query logic and provides a fluent interface.
# Implements medical message querying with optimized database operations.
class MessageQuery
  attr_reader :relation

  def initialize(relation = Message.all)
    @relation = relation
  end

  # == Status-Based Queries ==

  # Find unread messages for notification and display purposes.
  def unread
    self.class.new(@relation.where(read: false))
  end

  # Find read messages for conversation history.
  def read
    self.class.new(@relation.where(read: true))
  end

  # Filter messages by specific status.
  # Supports sent, delivered, and read status filtering.
  def by_status(status)
    self.class.new(@relation.where(status: status))
  end

  # == Routing Queries ==

  # Filter messages by routing type.
  # Supports direct, reply, and auto routing type filtering.
  def by_routing_type(routing_type)
    self.class.new(@relation.where(routing_type: routing_type))
  end

  # Find direct messages (new conversations).
  # Used for identifying new patient-doctor communications.
  def direct_messages
    self.class.new(@relation.where(routing_type: :direct))
  end

  # Find reply messages (threaded conversations).
  # Used for identifying conversation continuations.
  def replies
    self.class.new(@relation.where(routing_type: :reply))
  end

  # Find auto-routed messages (system-routed).
  # Used for identifying system-managed message routing.
  def auto_routed
    self.class.new(@relation.where(routing_type: :auto))
  end

  # == Conversation Threading Queries ==

  # Finds all messages in a conversation thread (root + all replies).
  # Essential for conversation display and threading analysis.
  def conversation_thread(root_id)
    self.class.new(@relation.where(id: root_id).or(@relation.where(parent_message_id: root_id)))
  end

  # Eager loads user associations for conversation display optimization.
  # Prevents N+1 queries when displaying conversation participants.
  def with_conversation_users
    self.class.new(@relation.includes(outbox: :user, inbox: :user))
  end

  # == Temporal Queries ==

  # Find recent messages with optional limit.
  # Used for inbox display and recent activity tracking.
  def recent(limit = 10)
    self.class.new(@relation.order(created_at: :desc).limit(limit))
  end

  # Find messages created after specified timestamp.
  # Used for temporal filtering and activity analysis.
  def created_after(timestamp)
    self.class.new(@relation.where(created_at: timestamp..))
  end

  # Find messages created before specified timestamp.
  # Used for temporal filtering and activity analysis.
  def created_before(timestamp)
    self.class.new(@relation.where(created_at: ..timestamp))
  end

  # == Execution Interface ==

  delegate :to_a, to: :@relation
  delegate :count, to: :@relation
  delegate :exists?, to: :@relation

  # == Method Chaining Support ==

  # Enables delegation to ActiveRecord::Relation while maintaining chainability.
  # Automatically wraps ActiveRecord::Relation results to preserve query object interface.
  # This allows seamless integration with ActiveRecord query methods.
  def method_missing(method_name, *, &)
    if @relation.respond_to?(method_name)
      result = @relation.public_send(method_name, *, &)
      result.is_a?(ActiveRecord::Relation) ? self.class.new(result) : result
    else
      super
    end
  end

  # Support for method_missing delegation.
  # Ensures proper method lookup for delegated ActiveRecord methods.
  def respond_to_missing?(method_name, include_private = false)
    @relation.respond_to?(method_name) || super
  end
end
