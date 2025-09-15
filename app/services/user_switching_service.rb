# frozen_string_literal: true

# Service for handling user role switching in development/demo environments.
# Provides session-based user switching without affecting authentication logic.
class UserSwitchingService
  class << self
    # Switch to a specific user role and store in thread
    def switch_to_role(session, role)
      user = find_user_by_role(role)

      if user
        # Store in both session (for persistence) and thread (for immediate access)
        session[:demo_user_id] = user.id
        User.current_demo_user = user
        Rails.logger.info "Switched to demo user: #{user.role} (#{user.full_name})"
      else
        Rails.logger.error "Failed to find user for role: #{role}"
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
      User.clear_demo_user
    end

    # Check if demo switching is active
    def demo_switching_active?(session)
      session[:demo_user_id].present?
    end

    # Restore demo user from session to thread (for new requests)
    def restore_demo_user_from_session(session)
      demo_user_id = session[:demo_user_id]
      return unless demo_user_id

      user = User.find_by(id: demo_user_id)
      if user
        User.current_demo_user = user
        Rails.logger.debug "Restored demo user context: #{user.role} (#{user.full_name})"
      else
        # Clear invalid session data
        session.delete(:demo_user_id)
        Rails.logger.warn "Invalid demo user ID #{demo_user_id} removed from session"
      end
    end

    # Get available roles for switching
    def available_roles
      [
        { role: 'patient', label: '👩‍⚕️ Patient', user: User.patient.first },
        { role: 'doctor', label: '🩺 Doctor', user: User.doctor.first },
        { role: 'admin', label: '⚙️ Admin', user: User.admin.first }
      ].select { |role_info| role_info[:user].present? }
    end

    private

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
