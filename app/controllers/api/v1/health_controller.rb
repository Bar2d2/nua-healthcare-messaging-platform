# frozen_string_literal: true

module Api
  module V1
    class HealthController < BaseController
      skip_before_action :authenticate_api_user!, only: [:show]

      # GET /api/v1/health
      def show
        render_success({
                         status: 'ok',
                         environment: Rails.env,
                         database: database_status,
                         message_routing: routing_service_status
                       })
      end

      private

      # Check database connection status.
      def database_status
        User.connection.active? ? 'connected' : 'disconnected'
      rescue StandardError
        'error'
      end

      # Check message routing service availability.
      def routing_service_status
        return 'available' if User.doctor.any? || User.admin.any?

        'no_recipients_available'
      rescue StandardError
        'error'
      end
    end
  end
end
