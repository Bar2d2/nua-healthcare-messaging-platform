# frozen_string_literal: true

module Api
  # Clean controller mixin that provides API functionality without bloating the controller
  module BaseControllerSupport
    extend ActiveSupport::Concern

    included do
      # Skip CSRF protection for API requests
      skip_before_action :verify_authenticity_token

      # Setup authentication
      before_action :authenticate_api_user!

      # Setup exception handling - Rails processes rescue_from in REVERSE order
      rescue_from StandardError, with: :handle_api_exception
      rescue_from ActiveRecord::RecordNotSaved, with: :handle_api_exception
      rescue_from ActiveRecord::RecordInvalid, with: :handle_api_exception
      rescue_from ActiveRecord::RecordNotFound, with: :handle_api_exception
      rescue_from ActionController::UnpermittedParameters, with: :handle_api_exception
      rescue_from ActionController::ParameterMissing, with: :handle_api_exception
      rescue_from Messages::Operations::RoutingService::NoAdminAvailableError, with: :handle_api_exception
      rescue_from Messages::Operations::RoutingService::NoDoctorAvailableError, with: :handle_api_exception
    end

    protected

    def current_user
      @current_user ||= Api::AuthenticationService.current_user
    end

    def authenticate_api_user!
      return if Api::AuthenticationService.authenticated?(current_user)

      render json: { error: 'Authentication required' }, status: :unauthorized
    end

    # Convenient rendering methods that delegate to ResponseService
    def render_success(data, status: :ok, message: nil)
      response_service.render_success(data, status: status, message: message)
    end

    def render_error(message, status: :unprocessable_entity, details: nil)
      response_service.render_error(message, status: status, details: details)
    end

    def render_collection(collection, serializer_class)
      response_service.render_collection(collection, serializer_class)
    end

    def render_resource(resource, serializer_class, status: :ok, message: nil)
      response_service.render_resource(resource, serializer_class, status: status, message: message)
    end

    private

    def response_options(status: :ok, message: nil)
      { status: status, message: message }
    end

    def handle_api_exception(exception)
      exception_handler.handle_exception(exception)
    end

    def response_service
      @response_service ||= Api::ResponseService.new(self)
    end

    def exception_handler
      @exception_handler ||= Api::ExceptionHandler.new(self)
    end
  end
end
