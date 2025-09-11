# frozen_string_literal: true

# Shared authentication steps for all user journeys
# Handles user login and role switching

# Basic authentication is handled by existing shared_setup_steps.rb

When('I switch to {word} role') do |role|
  # Use the existing user switching functionality with correct POST routes
  case role
  when 'patient'
    page.driver.post(switch_to_patient_path)
    visit root_path  # Navigate to see the change
    @current_user = @patient
  when 'doctor'
    page.driver.post(switch_to_doctor_path)
    visit root_path  # Navigate to see the change
    @current_user = @doctor
  when 'admin'
    page.driver.post(switch_to_admin_path)
    visit root_path  # Navigate to see the change
    @current_user = @admin
  end
end
