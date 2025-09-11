# frozen_string_literal: true

module SharedSetup
  def create_test_users
    create_patient
    create_doctor
    create_admin
    ensure_boxes_exist
  end

  def create_patient
    @patient = User.find_or_create_by!(first_name: 'Luke', last_name: 'Skywalker') do |user|
      user.is_patient = true
      user.is_doctor = false
      user.is_admin = false
    end
  end

  def create_doctor
    @doctor = User.find_or_create_by!(first_name: 'Leia', last_name: 'Organa') do |user|
      user.is_patient = false
      user.is_doctor = true
      user.is_admin = false
    end
  end

  def create_admin
    @admin = User.find_or_create_by!(first_name: 'Obi-wan', last_name: 'Kenobi') do |user|
      user.is_patient = false
      user.is_doctor = false
      user.is_admin = true
    end
  end

  def ensure_boxes_exist
    [@patient, @doctor, @admin].each do |user|
      user.inbox || user.create_inbox!
      user.outbox || user.create_outbox!
    end
  end

  def setup_authentication
    @current_user = @patient
    # Set the current user for the application
    User.class_eval do
      def self.current
        User.find_by(first_name: 'Luke', last_name: 'Skywalker')
      end
    end
  end

  def reset_user_current
    # Reset User.current to the original implementation
    User.class_eval do
      def self.current
        # Check for demo user switching in non-production environments
        unless Rails.env.production?
          demo_user_id = Thread.current[:demo_user_id]
          if demo_user_id
            demo_user = User.find_by(id: demo_user_id)
            return demo_user if demo_user
          end
        end

        User.patient.first
      end
    end
  end

  def cleanup_test_data
    Message.destroy_all
    Inbox.destroy_all
    Outbox.destroy_all
    User.destroy_all
  end
end

World(SharedSetup)

Before do
  create_test_users
  setup_authentication
end

After do
  # Clear user caches to prevent interference between scenarios
  Messages::Operations::RoutingService.clear_user_cache
  reset_user_current
  cleanup_test_data
end
