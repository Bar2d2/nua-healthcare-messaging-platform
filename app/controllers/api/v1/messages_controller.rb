# frozen_string_literal: true

module Api
  module V1
    class MessagesController < BaseController
      # PATCH /api/v1/messages/:id
      def update
        message = find_message_by_id
        return render_error('Message not found', status: :not_found) unless message

        message_params = MessageUpdateParams.new(params[:message])
        return handle_validation_errors(message_params) unless message_params.valid?

        update_message(message, message_params)
      end

      private

      def update_message(message, message_params)
        result = Messages::Operations::UpdateService.new(message, message_params).call
        handle_update_result(result)
      end

      # Ensures users can only update messages in their inbox.
      def find_message_by_id
        Message.joins(:inbox).where(id: params[:id], inboxes: { user: User.current }).first
      end

      # Returns standardized error response for parameter validation failures.
      def handle_validation_errors(message_params)
        render_error('Failed to update message',
                     details: message_params.errors.full_messages,
                     status: :unprocessable_entity)
      end

      # Processes ResponseResult and renders success or error response.
      def handle_update_result(result)
        if result.success?
          render_resource(result.data, MessageSerializer, message: 'Message updated successfully')
        else
          render_error(result.error_message, details: result.error_details, status: :unprocessable_entity)
        end
      end
    end
  end
end
