# frozen_string_literal: true

# Represents message routing types in medical communication system.
#
# Routing Types:
# - DIRECT: New conversation between patient and doctor
# - REPLY: Response to existing conversation thread
# - AUTO: System-routed (old conversations to admin)
#
# Usage:
#   MessageRoutingType.new(:direct).direct? # => true
#   MessageRoutingType.determine_for_message(message) # => routing type instance
class MessageRoutingType
  # Available routing types for medical messages
  DIRECT = 'direct'
  REPLY = 'reply'
  AUTO = 'auto'

  VALID_TYPES = [DIRECT, REPLY, AUTO].freeze

  # == Public Interface ==

  # Creates immutable routing type instance with validation
  def initialize(routing_type)
    @routing_type = routing_type.to_s
    validate_routing_type!
    freeze # Ensures immutability
  end

  # == Factory Methods ==

  class << self
    # New conversation between patient and doctor
    def direct
      new(DIRECT)
    end

    # Response to existing conversation thread
    def reply
      new(REPLY)
    end

    # System-routed (old conversations to admin)
    def auto
      new(AUTO)
    end

    # Determines routing type based on message threading context
    # Returns REPLY for threaded messages, DIRECT for new conversations
    def determine_for_message(message)
      return reply if message.parent_message_id.present?

      direct
    end
  end

  # == Predicate Methods ==

  # Check if routing type is direct (new conversation)
  def direct?
    routing_type == DIRECT
  end

  # Check if routing type is reply (threaded conversation)
  def reply?
    routing_type == REPLY
  end

  # Check if routing type is auto (system-routed)
  def auto?
    routing_type == AUTO
  end

  # == Comparison and Conversion ==

  # Compare routing type instances for equality
  def ==(other)
    return false unless other.is_a?(self.class)

    routing_type == other.routing_type
  end

  # Convert routing type to string representation
  def to_s
    routing_type
  end

  delegate :to_sym, to: :routing_type

  attr_reader :routing_type

  private

  # Validate routing type and raise error if invalid
  def validate_routing_type!
    return if VALID_TYPES.include?(@routing_type)

    raise ArgumentError, "Invalid routing type: #{@routing_type}"
  end
end
