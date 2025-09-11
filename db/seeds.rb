# Comprehensive seed data for medical communication system demo
# Creates users, messages, and conversation threads to showcase all functionality

require 'faker'

# Temporarily disable background jobs during seeding to prevent counter interference
original_adapter = ActiveJob::Base.queue_adapter
ActiveJob::Base.queue_adapter = :test

# Clear existing data for clean demo
Message.destroy_all
User.destroy_all

# Create diverse users for comprehensive demo using Faker
patients = [
  User.create!(first_name: 'Luke', last_name: 'Skywalker', is_patient: true, is_doctor: false, is_admin: false),
  User.create!(first_name: Faker::Name.first_name, last_name: Faker::Name.last_name, is_patient: true, is_doctor: false, is_admin: false),
  User.create!(first_name: Faker::Name.first_name, last_name: Faker::Name.last_name, is_patient: true, is_doctor: false, is_admin: false)
]

doctors = [
  User.create!(first_name: 'Leia', last_name: 'Organa', is_patient: false, is_doctor: true, is_admin: false),
  User.create!(first_name: Faker::Name.first_name, last_name: Faker::Name.last_name, is_patient: false, is_doctor: true, is_admin: false),
  User.create!(first_name: Faker::Name.first_name, last_name: Faker::Name.last_name, is_patient: false, is_doctor: true, is_admin: false)
]

admins = [
  User.create!(first_name: 'Obi-wan', last_name: 'Kenobi', is_patient: false, is_doctor: false, is_admin: true)
]

# Ensure inbox/outbox creation
(patients + doctors + admins).each do |user|
  user.create_inbox! unless user.inbox
  user.create_outbox! unless user.outbox
end

# Scenario 1: Recent patient-doctor conversation using Faker
patient1 = patients[0]  # Luke Skywalker
doctor1 = doctors[0]    # Leia Organa

# Patient initiates conversation
msg1 = Message.create!(
  body: "Hello Dr. #{doctor1.last_name}, #{Faker::Lorem.sentence(word_count: 15)}",
  outbox: patient1.outbox,
  inbox: doctor1.inbox,
  read: false,
  status: :sent,
  routing_type: :direct,
  created_at: 2.days.ago
)

# Doctor replies
msg2 = Message.create!(
  body: "Hello #{patient1.first_name}, #{Faker::Lorem.sentence(word_count: 20)}",
  outbox: doctor1.outbox,
  inbox: patient1.inbox,
  parent_message: msg1,
  read: true,
  status: :read,
  routing_type: :reply,
  created_at: 1.day.ago
)

# Patient replies back
Message.create!(
  body: "Thank you Dr. #{doctor1.last_name}! #{Faker::Lorem.sentence(word_count: 18)}",
  outbox: patient1.outbox,
  inbox: doctor1.inbox,
  parent_message: msg1,
  read: false,
  status: :sent,
  routing_type: :reply,
  created_at: 6.hours.ago
)

# Scenario 2: Old conversation routed to admin
patient2 = patients[1]
doctor2 = doctors[1]
admin1 = admins[0]

# Old patient message (>1 week)
old_msg = Message.create!(
  body: "Dr. #{doctor2.last_name}, #{Faker::Lorem.sentence(word_count: 12)}",
  outbox: patient2.outbox,
  inbox: doctor2.inbox,
  read: true,
  status: :read,
  routing_type: :direct,
  created_at: 2.weeks.ago
)

# Patient follows up (routes to admin due to age)
Message.create!(
  body: "Following up on my previous message. #{Faker::Lorem.sentence(word_count: 15)}",
  outbox: patient2.outbox,
  inbox: admin1.inbox,
  parent_message: old_msg,
  read: false,
  status: :sent,
  routing_type: :reply,
  created_at: 3.days.ago
)

# Admin response
Message.create!(
  body: "Hello #{patient2.first_name}, #{Faker::Lorem.sentence(word_count: 16)}",
  outbox: admin1.outbox,
  inbox: patient2.inbox,
  parent_message: old_msg,
  read: false,
  status: :sent,
  routing_type: :reply,
  created_at: 2.days.ago
)

# Scenario 3: Doctor-initiated communication
patient3 = patients[2]
doctor3 = doctors[2]

# Doctor sends proactive message
msg3 = Message.create!(
  body: "Hello #{patient3.first_name}, #{Faker::Lorem.sentence(word_count: 14)}",
  outbox: doctor3.outbox,
  inbox: patient3.inbox,
  read: false,
  status: :sent,
  routing_type: :direct,
  created_at: 1.day.ago
)

# Patient responds
Message.create!(
  body: "Thank you Dr. #{doctor3.last_name}! #{Faker::Lorem.sentence(word_count: 17)}",
  outbox: patient3.outbox,
  inbox: doctor3.inbox,
  parent_message: msg3,
  read: false,
  status: :sent,
  routing_type: :reply,
  created_at: 12.hours.ago
)

# Scenario 4: Admin-initiated system communication
# Admin sends system update to all patients
[patient1, patient2, patient3].each do |patient|
  Message.create!(
    body: "System Update: #{Faker::Lorem.sentence(word_count: 20)}",
    outbox: admin1.outbox,
    inbox: patient.inbox,
    read: false,
    status: :sent,
    routing_type: :direct,
    created_at: 4.hours.ago
  )
end

# Scenario 5: Additional realistic messages using Faker
5.times do
  sender = (patients + doctors).sample
  receiver = (patients + doctors + admins - [sender]).sample

  Message.create!(
    body: Faker::Lorem.sentence(word_count: rand(10..25)),
    outbox: sender.outbox,
    inbox: receiver.inbox,
    read: [true, false].sample,
    status: [:sent, :delivered, :read].sample,
    routing_type: :direct,
    created_at: Faker::Time.between(from: 1.week.ago, to: 1.hour.ago)
  )
end

# Recalculate unread counts for all inboxes after seed data creation
# This ensures the counts are accurate since we created messages directly
puts ""
puts "Recalculating unread counts..." unless Rails.env.test?

# Use direct SQL to avoid triggering callbacks/jobs
Inbox.find_each do |inbox|
  unread_count = inbox.messages.where(read: false).count
  inbox.update_column(:unread_count, unread_count)
end

# Restore original job adapter
ActiveJob::Base.queue_adapter = original_adapter

puts ""
puts "✅ Seed data created successfully!" unless Rails.env.test?
puts ""

# Display summary of created data
unless Rails.env.test?
  puts "📊 Summary:"
  puts "  • #{User.count} users created (#{User.where(is_patient: true).count} patients, #{User.where(is_doctor: true).count} doctors, #{User.where(is_admin: true).count} admins)"
  puts "  • #{Message.count} messages created"
  puts "  • #{Inbox.sum(:unread_count)} total unread messages"
  puts ""
end
