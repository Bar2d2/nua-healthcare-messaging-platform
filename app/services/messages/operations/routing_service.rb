# frozen_string_literal: true

module Messages
  module Operations
    # Intelligent message routing for medical communication system.
    # Routes messages between patients, doctors, and admins based on business rules.
    class RoutingService
      attr_reader :message, :request_user

      def initialize(message, request_user)
        @message = message
        @request_user = request_user
      end

      # == Public Interface ==

      # Routes messages based on sender role and conversation context
      def determine_recipient
        return handle_reply_routing if message.reply?

        route_by_user_role
      end

      # Determine routing type based on message context
      def determine_routing_type
        return :reply if message.parent_message.present?

        :direct
      end

      class << self
        # Class method for determining routing type
        def determine_routing_type(message)
          return :reply if message.parent_message.present?

          :direct
        end

        # == Performance: Cached User Lookups ==

        # Cache frequently accessed doctor (expires every hour)
        def cached_doctor
          if @cached_doctor_expires.nil? || Time.current > @cached_doctor_expires
            @cached_doctor = User.doctor.first || User.default_doctor
            @cached_doctor_expires = 1.hour.from_now
          end
          @cached_doctor
        end

        # Cache frequently accessed admin (expires every hour)
        def cached_admin
          if @cached_admin_expires.nil? || Time.current > @cached_admin_expires
            @cached_admin = User.admin.first || User.default_admin
            @cached_admin_expires = 1.hour.from_now
          end
          @cached_admin
        end

        # Clear user caches (for testing or when users change)
        def clear_user_cache
          @cached_doctor = nil
          @cached_admin = nil
          @cached_doctor_expires = nil
          @cached_admin_expires = nil
        end
      end

      private

      def route_by_user_role
        user_role = request_user.role
        case user_role
        when 'patient'
          handle_patient_sending
        when 'doctor'
          handle_doctor_sending
        when 'admin'
          handle_admin_sending
        else
          raise UnsupportedUserRoleError, "Unsupported user role: #{user_role}"
        end
      end

      # == Role-Based Routing ==

      # Handle patient sending messages (existing logic)
      def handle_patient_sending
        if recent_conversation?
          # Try to find doctor first, fallback to admin if no doctor available
          begin
            find_doctor
          rescue NoDoctorAvailableError
            find_admin
          end
        else
          find_admin
        end
      end

      # Handle doctor sending messages to patients
      def handle_doctor_sending
        parent_message = message.parent_message
        if parent_message.present?
          # Reply to existing conversation - route to conversation owner (patient)
          conversation_owner = parent_message.conversation_owner
          return conversation_owner if conversation_owner.is_patient?
        end

        # New message from doctor - find a patient
        find_patient
      end

      # Handle admin sending messages to patients
      def handle_admin_sending
        parent_message = message.parent_message
        if parent_message.present?
          # Reply to existing conversation - route to conversation owner (patient)
          conversation_owner = parent_message.conversation_owner
          return conversation_owner if conversation_owner.is_patient?
        end

        # New message from admin - find a patient
        find_patient
      end

      # == Business Rule Implementation ==

      # Handle reply routing - maintain conversation with same participants when possible
      def handle_reply_routing
        parent_message = message.parent_message
        return find_doctor unless parent_message

        conversation_owner = parent_message.conversation_owner

        # If the conversation owner is the request_user, route based on conversation age
        return route_based_on_conversation_age(parent_message) if conversation_owner == request_user

        # If the conversation owner is not the request_user, route to the conversation owner
        # UNLESS the conversation is old, then route to admin
        return route_to_conversation_owner(conversation_owner) if recent_conversation?

        find_admin
      end

      # Route to the conversation owner when sender is not the owner
      def route_to_conversation_owner(conversation_owner)
        conversation_owner
      end

      # Route based on conversation age when sender is the conversation owner
      def route_based_on_conversation_age(parent_message)
        if recent_conversation?
          conversation_doctor = parent_message.conversation_doctor
          conversation_doctor || find_doctor
        else
          find_admin
        end
      end

      # Business rule: conversations older than 1 week route to admin
      def recent_conversation?
        parent_message = message.parent_message
        return true if parent_message.blank?

        parent_message.created_at > 1.week.ago
      end

      # == Recipient Lookup ==

      # Find available doctor for medical consultation (with caching)
      def find_doctor
        self.class.cached_doctor || raise(NoDoctorAvailableError)
      end

      # Find available admin for administrative tasks (with caching)
      def find_admin
        self.class.cached_admin || raise(NoAdminAvailableError)
      end

      # Find available patient for doctor/admin communication
      def find_patient
        User.patient.first || raise(NoPatientAvailableError)
      end

      # == Custom Error Classes ==

      # Raised when no doctor is available to handle medical consultation routing
      class NoDoctorAvailableError < StandardError; end

      # Raised when no admin is available to handle old conversation routing
      class NoAdminAvailableError < StandardError; end

      # Raised when no patient is available for doctor/admin communication
      class NoPatientAvailableError < StandardError; end

      # Raised when user role is not supported
      class UnsupportedUserRoleError < StandardError; end
    end
  end
end
