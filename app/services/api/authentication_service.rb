# frozen_string_literal: true

module Api
  # Handles API authentication logic
  class AuthenticationService
    class << self
      attr_writer :current_user

      def current_user
        return @current_user if defined?(@current_user) && @current_user

        # TODO: Implement proper JWT authentication
        # For now, return first patient for development
        user = User.patient.first
        # Ensure user has inbox and outbox for API operations
        if user
          user.inbox ||= user.create_inbox
          user.outbox ||= user.create_outbox
        end
        user
      end

      def authenticated?(user)
        user.present?
      end

      def reset!
        @current_user = nil
      end
    end
  end
end
