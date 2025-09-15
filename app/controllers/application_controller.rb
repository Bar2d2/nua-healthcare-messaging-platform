# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pagy::Backend # Add Pagy backend for high-performance pagination

  protect_from_forgery with: :exception

  # Restore demo user from session for user switching functionality (enabled for demo purposes)
  before_action :restore_demo_user_from_session

  # Make current_user available to all views
  helper_method :current_user

  private

  # Get the current user for the application
  def current_user
    @current_user ||= User.current
  end

  # Restore demo user switching state from session
  def restore_demo_user_from_session
    UserSwitchingService.restore_demo_user_from_session(session)
  end
end
