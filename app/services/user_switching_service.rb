# frozen_string_literal: true

# Service for handling user role switching in development/demo environments.
# Provides session-based user switching without affecting authentication logic.
class UserSwitchingService
  class << self
    # Switch to a specific user role and store in session only
    def switch_to_role(session, role)
      user = find_user_by_role(role)

      if user
        store_user_in_session(session, user)
      else
        log_role_switch_failure(role)
      end

      user
    end

    # Get the current demo user from session
    def current_demo_user(session)
      demo_user_id = session[:demo_user_id]
      return nil unless demo_user_id

      User.find_by(id: demo_user_id)
    end

    # Clear demo user switching (return to default)
    def clear_demo_user(session)
      session.delete(:demo_user_id)
      Rails.logger.info 'Cleared demo user switching - returned to default user'
    end

    # Check if demo switching is active
    def demo_switching_active?(session)
      session[:demo_user_id].present?
    end

    # Validate and clean session data (no thread restoration needed)
    def restore_demo_user_from_session(session)
      demo_user_id = session[:demo_user_id]
      return unless demo_user_id

      validate_and_log_demo_user(session, demo_user_id)
    end

    private

    def store_user_in_session(session, user)
      session[:demo_user_id] = user.id
      Rails.logger.info "Switched to demo user: #{user.role} (#{user.full_name})"
    end

    def log_role_switch_failure(role)
      Rails.logger.error "Failed to find user for role: #{role}"
    end

    def validate_and_log_demo_user(session, demo_user_id)
      user = User.find_by(id: demo_user_id)

      if user
        log_demo_user_validation_success(user)
      else
        clear_invalid_session_data(session, demo_user_id)
      end
    end

    def log_demo_user_validation_success(user)
      Rails.logger.debug { "Demo user context validated: #{user.role} (#{user.full_name})" }
    end

    def clear_invalid_session_data(session, demo_user_id)
      session.delete(:demo_user_id)
      Rails.logger.warn "Invalid demo user ID #{demo_user_id} removed from session"
    end

    # Get available roles for switching
    def available_roles
      [
        { role: 'patient', label: '👩‍⚕️ Patient', user: User.patient.first },
        { role: 'doctor', label: '🩺 Doctor', user: User.doctor.first },
        { role: 'admin', label: '⚙️ Admin', user: User.admin.first }
      ].select { |role_info| role_info[:user].present? }
    end

    def find_user_by_role(role)
      patient_user = User.patient.first

      case role.to_s.downcase
      when 'patient'
        patient_user
      when 'doctor'
        User.doctor.first
      when 'admin'
        User.admin.first
      else
        handle_unknown_role(role, patient_user)
      end
    end

    def handle_unknown_role(role, patient_user)
      # Default fallback to patient for unknown roles
      Rails.logger.warn "Unknown role '#{role}', defaulting to patient"
      patient_user
    end
  end
end
