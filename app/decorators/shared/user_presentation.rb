# frozen_string_literal: true

module Shared
  # Reusable user presentation logic for helpers and decorators.
  # Provides consistent user display methods across the application.
  module UserPresentation
    # Get icon for user role.
    def role_icon(role)
      case role.to_s
      when 'patient'
        '👩‍⚕️'
      when 'doctor'
        '🩺'
      when 'admin'
        '⚙️'
      else
        '👤'
      end
    end
  end
end
