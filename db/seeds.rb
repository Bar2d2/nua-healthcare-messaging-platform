# Comprehensive seed data for medical communication system demo
# Creates users, messages, and conversation threads to showcase all functionality

# Temporarily disable background jobs during seeding to prevent counter interference
original_adapter = ActiveJob::Base.queue_adapter
ActiveJob::Base.queue_adapter = :test

# Clear existing data for clean demo
Message.destroy_all
User.destroy_all

# Create diverse users for comprehensive demo
patients = [
  User.create!(first_name: 'Luke', last_name: 'Skywalker', is_patient: true, is_doctor: false, is_admin: false),
  User.create!(first_name: 'Sarah', last_name: 'Johnson', is_patient: true, is_doctor: false, is_admin: false),
  User.create!(first_name: 'Michael', last_name: 'Brown', is_patient: true, is_doctor: false, is_admin: false)
]

doctors = [
  User.create!(first_name: 'Leia', last_name: 'Organa', is_patient: false, is_doctor: true, is_admin: false),
  User.create!(first_name: 'Dr. Emma', last_name: 'Wilson', is_patient: false, is_doctor: true, is_admin: false),
  User.create!(first_name: 'Dr. James', last_name: 'Davis', is_patient: false, is_doctor: true, is_admin: false)
]

admins = [
  User.create!(first_name: 'Obi-wan', last_name: 'Kenobi', is_patient: false, is_doctor: false, is_admin: true)
]

# Ensure inbox/outbox creation
(patients + doctors + admins).each do |user|
  user.create_inbox! unless user.inbox
  user.create_outbox! unless user.outbox
end

# Scenario 1: Recent patient-doctor conversation
patient1 = patients[0]  # Luke Skywalker
doctor1 = doctors[0]    # Leia Organa

# Patient initiates conversation
msg1 = Message.create!(
  body: "Hello Dr. #{doctor1.last_name}, I've been experiencing some chest pain and shortness of breath. It started about 3 days ago and seems to get worse when I'm active. Should I be concerned?",
  outbox: patient1.outbox,
  inbox: doctor1.inbox,
  read: false,
  status: :sent,
  routing_type: :direct,
  created_at: 2.days.ago
)

# Doctor replies
msg2 = Message.create!(
  body: "Hello #{patient1.first_name}, thank you for reaching out. Chest pain and shortness of breath can be concerning symptoms. I'd like to schedule you for an appointment this week to evaluate this properly. Can you come in on Thursday at 2 PM?",
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
  body: "Thank you Dr. #{doctor1.last_name}! Thursday at 2 PM works perfectly for me. I'll make sure to bring my insurance card and any relevant medical records.",
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
  body: "Dr. #{doctor2.last_name}, I'm still experiencing the headaches we discussed last month. The medication you prescribed helped initially but the symptoms have returned.",
  outbox: patient2.outbox,
  inbox: doctor2.inbox,
  read: true,
  status: :read,
  routing_type: :direct,
  created_at: 2.weeks.ago
)

# Patient follows up (routes to admin due to age)
Message.create!(
  body: "Following up on my previous message about the headaches. I haven't heard back and I'm getting concerned. Could someone please review my case?",
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
  body: "Hello #{patient2.first_name}, I apologize for the delay in response. I've reviewed your case and Dr. #{doctor2.last_name} will be contacting you within 24 hours to discuss your treatment options.",
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
  body: "Hello #{patient3.first_name}, I wanted to follow up on your recent blood test results. Everything looks good, but I'd like to discuss your cholesterol levels at your next appointment.",
  outbox: doctor3.outbox,
  inbox: patient3.inbox,
  read: false,
  status: :sent,
  routing_type: :direct,
  created_at: 1.day.ago
)

# Patient responds
Message.create!(
  body: "Thank you Dr. #{doctor3.last_name}! I'm glad to hear the results are mostly good. I'll make sure to ask about the cholesterol levels during my next visit.",
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
    body: "System Update: Our patient portal will be undergoing maintenance this weekend from Saturday 10 PM to Sunday 6 AM. During this time, messaging features will be temporarily unavailable. We apologize for any inconvenience.",
    outbox: admin1.outbox,
    inbox: patient.inbox,
    read: false,
    status: :sent,
    routing_type: :direct,
    created_at: 4.hours.ago
  )
end

# Scenario 5: Additional realistic messages
Message.create!(
  body: "Dr. Wilson, I have a question about my prescription refill. The pharmacy said they need prior authorization. Can you help with this?",
  outbox: patient2.outbox,
  inbox: doctors[1].inbox,
  read: true,
  status: :read,
  routing_type: :direct,
  created_at: 1.week.ago
)

Message.create!(
  body: "Hello Sarah, I've submitted the prior authorization for your medication. It should be approved within 2-3 business days. I'll send you a message once it's processed.",
  outbox: doctors[1].outbox,
  inbox: patient2.inbox,
  read: false,
  status: :sent,
  routing_type: :direct,
  created_at: 5.days.ago
)

Message.create!(
  body: "Dr. Davis, I wanted to thank you for the excellent care during my recent visit. The treatment plan you recommended is working very well.",
  outbox: patient3.outbox,
  inbox: doctors[2].inbox,
  read: true,
  status: :read,
  routing_type: :direct,
  created_at: 3.days.ago
)

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