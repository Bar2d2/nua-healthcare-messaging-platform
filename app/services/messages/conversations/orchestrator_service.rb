# frozen_string_literal: true

module Messages
  module Conversations
    # Orchestrates message-related services for medical communication system.
    # Provides unified interface for message operations and service management.
    class OrchestratorService
      attr_reader :message

      def initialize(message)
        @message = message
        @services = {}
      end

      # == Service Accessors ==

      # Get conversation service for message
      def conversation
        @services[:conversation] ||= Messages::Conversations::DataService.new(message)
      end

      # Get status service for message
      def status
        @services[:status] ||= Messages::Operations::StatusService.new(message)
      end

      # Get routing service for message
      def routing
        @services[:routing] ||= Messages::Operations::RoutingService.new(message, message.outbox.user)
      end

      # Get participant service for message conversation
      def participants
        @services[:participants] ||= Messages::Participants::DataService.new(conversation.messages)
      end

      # == Service Delegation ==

      # Delegate conversation methods to conversation service
      def method_missing(method_name, *, &)
        if conversation.respond_to?(method_name)
          conversation.send(method_name, *, &)
        elsif status.respond_to?(method_name)
          status.send(method_name, *, &)
        elsif participants.respond_to?(method_name)
          participants.send(method_name, *, &)
        else
          super
        end
      end

      # Check if method is available on any service
      def respond_to_missing?(method_name, include_private = false)
        conversation.respond_to?(method_name, include_private) ||
          status.respond_to?(method_name, include_private) ||
          participants.respond_to?(method_name, include_private) ||
          super
      end

      # == Service Lifecycle Management ==

      # Reset all service instances
      def reset_services
        @services.clear
        self
      end

      # Preload all services
      def preload_services
        conversation
        status
        routing
        participants
        self
      end

      # == Service Health Check ==

      # Check if all services are properly initialized
      def services_healthy?
        conversation && status && participants
      end

      # Check if specific service is loaded
      def service_loaded?(service_name)
        case service_name
        when :conversation, :conversation_service
          @services.key?(:conversation)
        when :status, :status_service
          @services.key?(:status)
        when :routing_service
          @services.key?(:routing)
        when :participants, :member_service
          @services.key?(:participants)
        else
          false
        end
      end

      # Get list of currently loaded services
      def services_loaded
        service_mappings = {
          conversation: :conversation,
          status: :status,
          routing: :routing,
          participants: :member
        }

        service_mappings.select { |key, _| @services.key?(key) }.values
      end

      private

      # Validate message before service initialization
      def validate_message!
        raise ArgumentError, 'Message cannot be nil' if message.nil?
        raise ArgumentError, 'Message must be persisted' unless message.persisted?
      end
    end
  end
end
