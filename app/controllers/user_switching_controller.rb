# frozen_string_literal: true

# Controller for handling user role switching in development/demo environments.
# Provides simple actions to switch between patient, doctor, and admin roles.
class UserSwitchingController < ApplicationController
  # POST /demo/switch_to_patient
  def switch_to_patient
    switch_to_role_and_redirect('patient', 'Patient')
  end

  # POST /demo/switch_to_doctor
  def switch_to_doctor
    switch_to_role_and_redirect('doctor', 'Doctor')
  end

  # POST /demo/switch_to_admin
  def switch_to_admin
    switch_to_role_and_redirect('admin', 'Admin')
  end

  # POST /demo/clear_user_switch
  def clear_user_switch
    UserSwitchingService.clear_demo_user(session)
    flash[:notice] = t('user_switching.returned_to_default')
    redirect_back(fallback_location: root_path)
  end

  private

  # Common method for role switching and redirecting
  def switch_to_role_and_redirect(role, role_label)
    user = UserSwitchingService.switch_to_role(session, role)
    if user
      # Force a full page refresh to update all user-dependent content
      redirect_to request.referer || root_path, notice: "Switched to #{role_label}: #{user.full_name}"
    else
      redirect_back(fallback_location: root_path, alert: "Failed to switch to #{role_label}")
    end
  end

  # Ensure this functionality is only available in non-production environments
  def ensure_non_production_environment
    return unless Rails.env.production?

    head :not_found
  end
end
