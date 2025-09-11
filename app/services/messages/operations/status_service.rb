# frozen_string_literal: true

module Messages
  module Operations
    # Manages message status transitions in medical communication workflow.
    # Enforces business rules: sent -> delivered -> read progression.
    class StatusService
      attr_reader :message

      def initialize(message)
        @message = message
      end

      # == Status Validation ==

      # Check if status transition is allowed by business rules
      def can_transition_to?(target_status)
        transition_allowed?(target_status)
      end

      # Get available next statuses for current message state
      def available_transitions
        valid_transitions[message.status.to_sym]
      end

      # == Class Methods for Validation ==

      class << self
        # Check if message can transition to target status
        def can_transition_to?(message, target_status)
          new(message).can_transition_to?(target_status)
        end

        # Get available transitions for message
        def available_transitions(message)
          new(message).available_transitions
        end
      end

      private

      # Check if transition is allowed (internal validation)
      def transition_allowed?(status)
        valid_transitions[message.status.to_sym].include?(status.to_sym)
      end

      # Medical workflow: sent -> delivered -> read progression
      def valid_transitions
        {
          sent: %i[delivered read],
          delivered: [:read],
          read: [] # Terminal state
        }
      end
    end
  end
end
