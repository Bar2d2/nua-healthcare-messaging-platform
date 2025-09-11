# frozen_string_literal: true

module Api
  # Enhanced exception handling for API controllers.
  # Provides centralized exception logging and error response generation.
  class ExceptionHandler
    attr_reader :request

    def initialize(request)
      @request = request
      @response_service = Api::ResponseService.new(request)
    end

    # Handle exception and render appropriate error response
    def handle_exception(exception)
      log_exception(exception)

      error_config = ErrorRegistry.error_config_for(exception)
      response_data = build_response_data(exception, error_config)

      @response_service.render_error(
        response_data[:message],
        status: response_data[:status],
        details: response_data[:details]
      )
    end

    private

    # Log exception with appropriate level based on type
    def log_exception(exception)
      log_level, log_message = determine_log_level_and_message(exception)
      logger = Rails.logger
      logger.public_send(log_level, log_message)

      # Log backtrace for unhandled exceptions
      return unless log_level == :error && exception.backtrace

      logger.error exception.backtrace.join("\n")
    end

    # Determine appropriate log level and message for exception
    def determine_log_level_and_message(exception)
      message = exception.message

      case exception
      when ActiveRecord::RecordNotFound
        [:info, "API: Record not found - #{message}"]
      when ActionController::ParameterMissing, ActionController::UnpermittedParameters
        [:warn, "API: Parameter error - #{message}"]
      when Messages::Operations::RoutingService::NoDoctorAvailableError, Messages::Operations::RoutingService::NoAdminAvailableError
        [:info, "API: Service unavailable - #{message}"]
      else
        [:error, "API: Unhandled exception - #{exception.class}: #{message}"]
      end
    end

    # Build response data from exception and config
    def build_response_data(exception, config)
      response_data = {
        message: config[:message],
        status: config[:status],
        details: nil
      }
      if config[:include_details] && exception.respond_to?(:record)
        response_data[:details] = exception.record.errors.full_messages
      elsif config[:include_param] && exception.respond_to?(:param)
        response_data[:message] = "Missing parameter: #{exception.param}"
      end

      response_data
    end
  end
end
