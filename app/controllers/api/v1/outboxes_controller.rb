# frozen_string_literal: true

module Api
  module V1
    class OutboxesController < BaseController
      # POST /api/v1/outbox/messages
      def send_message
        message_params = MessageParams.new(params[:message])
        return handle_validation_errors(message_params) unless message_params.valid?

        Rails.logger.debug # Use synchronous processing for API (immediate response required)
        result = Messages::Operations::SendService.new(message_params, current_user).call

        if result.success?
          render_resource(result.data, MessageSerializer, status: :created, message: 'Message sent successfully')
        else
          render_error(result.error_message, details: result.error_details, status: :unprocessable_entity)
        end
      end

      private

      # Returns standardized error response for parameter validation failures.
      def handle_validation_errors(message_params)
        render_error('Failed to send message', details: message_params.errors.full_messages,
                                               status: :unprocessable_entity)
      end
    end
  end
end
