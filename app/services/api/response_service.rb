# frozen_string_literal: true

module Api
  # Renders consistent API responses with standardized format and metadata.
  class ResponseService
    attr_reader :request

    def initialize(request)
      @request = request
    end

    # == Public Interface ==

    # Render success response with standardized format
    def render_success(data, status: :ok, message: nil)
      response_body = build_success_response(data, message)
      request.render json: response_body, status: status
    end

    # Render error response with standardized format
    def render_error(message, status: :unprocessable_entity, details: nil)
      response_body = build_error_response(message, details)
      request.render json: response_body, status: status
    end

    # Render collection response with standardized format
    def render_collection(collection, serializer_class)
      serialized_data = collection.map { |item| serializer_class.new(item).attributes }
      render_success(serialized_data)
    end

    # Render single resource response with standardized format
    def render_resource(resource, serializer_class, status: :ok, message: nil)
      serialized_data = serializer_class.new(resource).attributes
      render_success(serialized_data, status: status, message: message)
    end

    # == Class Methods ==

    # Build response metadata for API consistency
    def self.build_metadata
      {
        timestamp: Time.current.iso8601,
        version: '1.0.0'
      }
    end

    private

    def response_params(status: :ok, message: nil)
      { status: status, message: message }
    end

    # == Private Methods ==

    # Build standardized success response structure
    def build_success_response(data, message)
      response_body = {
        data: data,
        meta: self.class.build_metadata
      }
      response_body[:message] = message if message.present?
      response_body
    end

    # Build standardized error response structure
    def build_error_response(message, details)
      response_body = {
        error: message,
        meta: self.class.build_metadata
      }
      response_body[:details] = details if details.present?
      response_body
    end
  end
end
