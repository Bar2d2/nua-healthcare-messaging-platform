# frozen_string_literal: true

module Messages
  module Operations
    # Updates message attributes with validation and error handling.
    # Handles message updates in medical communication workflow.
    class UpdateService
      attr_reader :message, :message_params

      def initialize(message, message_params)
        @message = message
        @message_params = message_params
      end

      # == Public Interface ==

      # Main service method - updates message with validated parameters
      # Returns ResponseResult with success status and error information
      def call
        unless message_params.valid?
          return Api::ResponseResult.failure('Invalid message parameters',
                                             message_params.errors.full_messages)
        end

        filtered_params = filter_blank_parameters
        return Api::ResponseResult.success(message) if filtered_params.empty?

        update_message(filtered_params)
      end

      private

      # == Parameter Processing ==

      # Filter out blank parameters to avoid unnecessary updates
      def filter_blank_parameters
        message_params.to_message_attributes.compact_blank
      end

      # == Error Handling ==

      # Update message with filtered parameters and handle errors
      def update_message(filtered_params)
        if message.update(filtered_params)
          Api::ResponseResult.success(message)
        else
          Api::ResponseResult.failure('Failed to update message', message.errors.full_messages)
        end
      rescue ArgumentError => e
        error_message = e.message
        Api::ResponseResult.failure('Invalid status', [error_message])
      end
    end
  end
end
