# frozen_string_literal: true

include Rails.application.routes.url_helpers

Given('the application is running') do
  # Application is already running in test environment
end

Given('I have test users in the system') do
  # Create test users with different roles using direct model creation
  @patient = User.create!(
    first_name: 'Test',
    last_name: 'Patient',
    is_patient: true,
    is_doctor: false,
    is_admin: false
  )

  @doctor = User.create!(
    first_name: 'Dr. Test',
    last_name: 'Doctor',
    is_patient: false,
    is_doctor: true,
    is_admin: false
  )

  # Use the same admin that seed data creates (for consistent routing)
  @admin = User.find_or_create_by!(first_name: 'Obi-wan', last_name: 'Kenobi') do |user|
    user.is_patient = false
    user.is_doctor = false
    user.is_admin = true
  end

  # Ensure inbox and outbox are created
  @patient.create_inbox! unless @patient.inbox
  @patient.create_outbox! unless @patient.outbox
  @doctor.create_inbox! unless @doctor.inbox
  @doctor.create_outbox! unless @doctor.outbox
  @admin.create_inbox! unless @admin.inbox
  @admin.create_outbox! unless @admin.outbox
end

Given('I am logged in as a patient') do
  # Override the User.current method for this test
  User.class_eval do
    def self.current
      User.find_by(first_name: 'Test', last_name: 'Patient')
    end
  end
  @current_user = @patient
end

Given('I am logged in as a doctor') do
  # Override the User.current method for this test
  User.class_eval do
    def self.current
      User.find_by(first_name: 'Dr. Test', last_name: 'Doctor')
    end
  end
  @current_user = @doctor
end

Given('I am logged in as an admin') do
  User.class_eval do
    def self.current
      User.find_by(first_name: 'Obi-wan', last_name: 'Kenobi')
    end
  end
  @current_user = @admin
end

Given('no doctors are available in the system') do
  User.where(is_doctor: true).destroy_all
  # Clear user cache to ensure routing service sees the change
  Messages::Operations::RoutingService.clear_user_cache
end

Given('no admins are available in the system') do
  User.where(is_admin: true).destroy_all
end

Given('no patients are available in the system') do
  User.where(is_patient: true).destroy_all
end

Given('no doctors or admins are available in the system') do
  User.where(is_doctor: true).destroy_all
  User.where(is_admin: true).destroy_all
end

Given('there is a message in my inbox') do
  sender = @current_user.is_patient? ? @doctor : @patient
  @message = Message.create!(
    outbox: sender.outbox,
    inbox: @current_user.inbox,
    body: 'Test message content',
    status: :sent,
    routing_type: :direct
  )
end

Given('there is a recent message from a doctor in my inbox') do
  @message = Message.create!(
    outbox: @doctor.outbox,
    inbox: @current_user.inbox,
    body: 'Recent message from doctor',
    status: :sent,
    routing_type: :direct,
    created_at: 2.days.ago
  )
end

Given('there is an old message from a doctor in my inbox') do
  @message = Message.create!(
    outbox: @doctor.outbox,
    inbox: @current_user.inbox,
    body: 'Old message from doctor',
    status: :sent,
    routing_type: :direct,
    created_at: 2.weeks.ago
  )
end

Given('there is a message from a patient in my inbox') do
  @message = Message.create!(
    outbox: @patient.outbox,
    inbox: @current_user.inbox,
    body: 'Message from patient',
    status: :sent,
    routing_type: :direct
  )
end

Given('there is a message in my outbox') do
  recipient = @current_user.is_patient? ? @doctor : @patient
  @message = Message.create!(
    outbox: @current_user.outbox,
    inbox: recipient.inbox,
    body: 'Sent message content',
    status: :sent,
    routing_type: :direct
  )
end

Given('there is a conversation with multiple messages') do
  # Create a conversation thread with multiple messages
  @root_message = Message.create!(
    outbox: @patient.outbox,
    inbox: @doctor.inbox,
    body: 'Initial message from patient',
    status: :sent,
    routing_type: :direct
  )

  @reply_message = Message.create!(
    outbox: @doctor.outbox,
    inbox: @patient.inbox,
    parent_message: @root_message,
    body: 'Reply from doctor',
    status: :sent,
    routing_type: :reply
  )

  @second_reply = Message.create!(
    outbox: @patient.outbox,
    inbox: @doctor.inbox,
    parent_message: @root_message,
    body: 'Second reply from patient',
    status: :sent,
    routing_type: :reply
  )
end

Given('there are unread messages in my inbox') do
  sender = @current_user.is_patient? ? @doctor : @patient
  @unread_messages = [
    Message.create!(
      outbox: sender.outbox,
      inbox: @current_user.inbox,
      body: 'Unread message 1',
      status: :sent,
      routing_type: :direct,
      read: false
    ),
    Message.create!(
      outbox: sender.outbox,
      inbox: @current_user.inbox,
      body: 'Unread message 2',
      status: :sent,
      routing_type: :direct,
      read: false
    )
  ]
end

Given('there is an unread message in my inbox') do
  sender = @current_user.is_patient? ? @doctor : @patient
  @unread_message = Message.create!(
    outbox: sender.outbox,
    inbox: @current_user.inbox,
    body: 'Unread message content',
    status: :sent,
    routing_type: :direct,
    read: false
  )
end

# Common assertions used across multiple journeys
Then('I should see message sent successfully') do
  # In test environment, we use synchronous processing
  expect(page).to have_content('Message was successfully created')
end

Then('I should see a success message') do
  expect(page).to have_content('Message was successfully created')
end

Then('the message should be routed to an admin') do
  # Wait for message creation to complete
  sleep(1)

  # Debug the message routing
  last_message = Message.last
  last_message&.inbox&.user

  # Check that the message was created and routed to an admin
  expect(last_message).to be_present, 'Message was not created'
  expect(last_message.inbox).to be_present, 'Message has no inbox'
  expect(last_message.inbox.user).to be_present, 'Inbox has no user'
  expect(last_message.inbox.user.is_admin?).to eq(true)
end
