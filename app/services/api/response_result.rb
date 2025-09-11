# frozen_string_literal: true

module Api
  # Standardized result object for API service responses.
  # Provides consistent result structure for success and error cases.
  # Implements medical communication service result patterns.
  class ResponseResult
    attr_reader :success, :data, :error_message, :error_details

    # == Public Interface ==

    # Create a new response result instance.
    def initialize(success:, data: nil, error_message: nil, error_details: nil)
      @success = success
      @data = data
      @error_message = error_message
      @error_details = error_details
    end

    # Check if the result represents a successful operation.
    def success?
      @success
    end

    # Check if the result represents a failed operation.
    def failure?
      !@success
    end

    # == Factory Methods ==

    class << self
      # Create a successful result with optional data.
      def success(data = nil)
        new(success: true, data: data)
      end

      # Create a failed result with error information.
      def failure(error_message, error_details = nil)
        new(success: false, error_message: error_message, error_details: error_details)
      end
    end

    # == Conversion Methods ==

    # Convert result to hash format for API responses.
    def to_hash
      {
        success?: success?,
        data: data,
        error_message: error_message,
        error_details: error_details
      }
    end

    # Convert result to hash format with string keys.
    def to_h
      to_hash.transform_keys(&:to_s)
    end
  end
end
