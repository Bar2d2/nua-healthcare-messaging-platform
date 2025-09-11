# frozen_string_literal: true

module Messages
  module Operations
    # Sends messages with intelligent routing and delivery in medical communication system.
    # Handles message creation, recipient determination, and delivery workflow.
    class SendService
      attr_reader :message_params, :request_user, :message

      def initialize(message_params, request_user)
        @message_params = message_params
        @request_user = request_user
        @message = nil
      end

      # == Public Interface ==

      # Main service method - orchestrates message creation, routing, and delivery
      # Returns ResponseResult with success status and error information
      def call
        build_message
        recipient = find_recipient
        return Api::ResponseResult.failure('No recipients available') unless recipient

        deliver_message(recipient)
      end

      private

      # == Message Building ==

      # Build message from parameters and set up associations
      def build_message
        @message = Message.new(message_params.to_message_attributes)
        message.outbox = request_user.outbox
        message.routing_type = message.determine_routing_type if message.routing_type.blank?
      end

      # == Recipient Determination ==

      # Find appropriate recipient using routing service (with preloading optimization)
      def find_recipient
        # Preload parent message associations if this is a reply
        preload_parent_message_if_needed

        routing_service = Messages::Operations::RoutingService.new(message, request_user)
        routing_service.determine_recipient
      rescue Messages::Operations::RoutingService::NoDoctorAvailableError,
             Messages::Operations::RoutingService::NoAdminAvailableError,
             Messages::Operations::RoutingService::NoPatientAvailableError,
             Messages::Operations::RoutingService::UnsupportedUserRoleError => e
        Rails.logger.error "Routing service error: #{e.message}"
        nil
      end

      # == Message Delivery ==

      # Deliver message to recipient by setting inbox and saving
      def deliver_message(recipient)
        message.inbox = recipient.inbox
        if message.save
          Api::ResponseResult.success(message)
        else
          Api::ResponseResult.failure('Failed to save message', message.errors.full_messages)
        end
      end

      # == Performance Optimizations ==

      # Preload parent message associations to avoid N+1 queries during routing
      def preload_parent_message_if_needed
        return if message.parent_message_id.blank?

        # Load parent message with all necessary associations for routing
        preloaded_parent = Message.includes(:outbox, :inbox,
                                            outbox: :user, inbox: :user)
                                  .find_by(id: message.parent_message_id)

        # Set the association to avoid additional queries
        message.parent_message = preloaded_parent if preloaded_parent
      end
    end
  end
end
