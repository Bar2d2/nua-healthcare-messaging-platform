# frozen_string_literal: true

namespace :messages do
  desc 'Generate messages for a specific user using Faker'
  task :generate, %i[first_name count] => :environment do |_t, args|
    require 'faker'

    # Parse arguments
    first_name = args[:first_name]
    count = (args[:count] || 1000).to_i

    # Validate arguments
    if first_name.blank?
      puts "❌ Error: Please provide a user's first name"
      puts 'Usage: rake messages:generate[Luke,1000]'
      puts '       rake messages:generate[Leia,500]'
      exit(1)
    end

    # Find the user
    user = User.find_by(first_name: first_name)
    unless user
      puts "❌ Error: User with first name '#{first_name}' not found"
      puts 'Available users:'
      User.find_each { |u| puts "  • #{u.first_name} #{u.last_name} (#{u.role})" }
      exit(1)
    end

    # Find potential recipients (all other users)
    recipients = User.where.not(id: user.id)
    if recipients.empty?
      puts '❌ Error: No other users available as recipients'
      exit(1)
    end

    puts "🎯 Generating #{count} messages for: #{user.first_name} #{user.last_name} (#{user.role})"
    puts "📨 Available recipients: #{recipients.count} users"
    puts ''

    # Temporarily disable callbacks to prevent broadcast storm
    puts '⚡ Disabling callbacks for high-speed generation...'
    Message.skip_callback(:commit, :after, :enqueue_broadcast_message)
    Message.skip_callback(:commit, :after, :enqueue_broadcast_update)
    Message.skip_callback(:commit, :after, :increment_inbox_unread_count)
    Message.skip_callback(:commit, :after, :handle_read_status_change)
    Message.skip_callback(:commit, :after, :invalidate_conversation_caches)

    # Medical message templates using Faker
    medical_templates = [
      lambda {
        "I've been experiencing #{Faker::Lorem.words(number: 3).join(' ')} and need medical advice. #{Faker::Lorem.sentence}"
      },
      -> { "Following up on #{Faker::Lorem.words(number: 2).join(' ')} treatment. #{Faker::Lorem.sentence}" },
      -> { "Could you review my #{Faker::Lorem.word} test results? #{Faker::Lorem.sentence}" },
      -> { "I'm having #{Faker::Lorem.word} symptoms. #{Faker::Lorem.sentence(word_count: rand(8..15))}" },
      -> { "My condition has #{%w[improved worsened stabilized].sample}. #{Faker::Lorem.sentence}" },
      lambda {
        "When should I schedule my next #{%w[appointment check-up consultation].sample}? #{Faker::Lorem.sentence}"
      },
      lambda {
        "The #{Faker::Lorem.word} treatment is #{['working well', 'not effective',
                                                  'causing side effects'].sample}. #{Faker::Lorem.sentence}"
      },
      -> { "I need to discuss #{Faker::Lorem.words(number: 2).join(' ')} options. #{Faker::Lorem.sentence}" },
      -> { "Could we explore alternative #{Faker::Lorem.word} treatments? #{Faker::Lorem.sentence}" },
      -> { "I have questions about my #{Faker::Lorem.word} diagnosis. #{Faker::Lorem.sentence}" }
    ]

    # Track timing
    start_time = Time.current
    created_count = 0

    puts '📨 Creating messages...'

    # Create messages in batches for better performance
    count.times do |i|
      recipient = recipients.sample

      Message.create!(
        body: medical_templates.sample.call,
        outbox: user.outbox,
        inbox: recipient.inbox,
        read: Faker::Boolean.boolean(true_ratio: 0.7), # 70% read
        status: %i[sent delivered read].sample,
        routing_type: :direct,
        created_at: Faker::Time.between(from: 60.days.ago, to: 1.hour.ago)
      )

      created_count += 1

      # Progress indicator every 100 messages
      next unless ((i + 1) % 100).zero?

      elapsed = Time.current - start_time
      rate = created_count / elapsed
      puts "  📈 #{i + 1}/#{count} messages created (#{rate.round(1)} msg/sec)"
    end

    total_time = Time.current - start_time

    # Re-enable callbacks
    puts ''
    puts '🔄 Re-enabling callbacks...'
    Message.set_callback(:commit, :after, :enqueue_broadcast_message)
    Message.set_callback(:commit, :after, :enqueue_broadcast_update)
    Message.set_callback(:commit, :after, :increment_inbox_unread_count)
    Message.set_callback(:commit, :after, :handle_read_status_change)
    Message.set_callback(:commit, :after, :invalidate_conversation_caches)

    # Recalculate unread counts for affected inboxes
    puts '📊 Recalculating unread counts for affected inboxes...'
    affected_inboxes = recipients.map(&:inbox).compact
    affected_inboxes.each(&:recalculate_unread_count!)

    puts ''
    puts "🎉 Successfully created #{created_count} messages!"
    puts "⏱️  Total time: #{total_time.round(2)} seconds"
    puts "📈 Average rate: #{(created_count / total_time).round(1)} messages/second"
    puts "📊 Total messages for #{user.first_name}: #{user.outbox.messages.count}"
    puts "📨 Total unread messages generated: #{affected_inboxes.sum(&:unread_count)}"
    puts ''
    puts '✅ Callbacks re-enabled - real-time features will work normally'
  end

  desc 'Show available users for message generation'
  task users: :environment do
    puts '📋 Available users for message generation:'
    puts ''

    User.all.group_by(&:role).each do |role, users|
      puts "#{role.capitalize.pluralize}:"
      users.each do |user|
        message_count = user.outbox.messages.count
        puts "  • #{user.first_name} #{user.last_name} (#{message_count} messages)"
      end
      puts ''
    end

    puts 'Usage examples:'
    puts '  rake messages:generate[Luke,1000]     # 1000 messages for Luke'
    puts '  rake messages:generate[Leia,500]      # 500 messages for Leia'
    puts '  rake messages:generate[Obi-wan,100]   # 100 messages for Obi-wan'
  end
end
