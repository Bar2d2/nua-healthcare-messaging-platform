# frozen_string_literal: true

module Api
  # Centralized registry of API error mappings and responses.
  # Maps exception classes to HTTP status codes and error messages for consistent API responses.
  class ErrorRegistry
    ERROR_MAPPINGS = {
      'Messages::Operations::RoutingService::NoDoctorAvailableError' => {
        status: :service_unavailable,
        message: 'No doctors are currently available'
      },
      'Messages::Operations::RoutingService::NoAdminAvailableError' => {
        status: :service_unavailable,
        message: 'No administrators are currently available'
      },
      'ActiveRecord::RecordNotFound' => {
        status: :not_found,
        message: 'Resource not found'
      },
      'ActiveRecord::RecordInvalid' => {
        status: :unprocessable_entity,
        message: 'Validation failed',
        include_details: true
      },
      'ActiveRecord::RecordNotSaved' => {
        status: :unprocessable_entity,
        message: 'Failed to save record'
      },
      'ActionController::ParameterMissing' => {
        status: :bad_request,
        message: 'Missing required parameter',
        include_param: true
      },
      'ActionController::UnpermittedParameters' => {
        status: :bad_request,
        message: 'Unpermitted parameters provided'
      }
    }.freeze

    class << self
      def error_config_for(exception)
        exception_class_name = exception.class.name
        ERROR_MAPPINGS[exception_class_name] || default_error_config
      end

      def default_error_config
        {
          status: :internal_server_error,
          message: 'Internal server error'
        }
      end

      def registered_exceptions
        ERROR_MAPPINGS.keys.filter_map do |class_name|
          class_name.constantize
        rescue NameError => e
          Rails.logger.warn "Could not load exception class: #{class_name} - #{e.message}"
          nil
        end
      end
    end
  end
end
