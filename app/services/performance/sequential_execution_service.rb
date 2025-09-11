# frozen_string_literal: true

# Sequential performance check for Redis + Sidekiq + Database
class Performance::SequentialExecutionService < Performance::BaseService
  def self.run(users: 10, messages: 5)
    new.check(users, messages)
  end

  def check(users, messages)
    puts ""
    puts "📈 SEQUENTIAL Performance Check: #{users} users × #{messages} messages"
    puts "   (Note: Tests one operation at a time)"
    puts "=" * 60

    # Start resource monitoring
    start_time = Time.current
    start_memory = get_memory_usage
    start_cpu = get_cpu_time

    # What we're testing
    redis_works = test_redis
    users_created = create_users(users, "Sequential")

    # Sequential message sending
    results = send_messages(users_created, messages)

    total_time = Time.current - start_time
    end_memory = get_memory_usage
    end_cpu = get_cpu_time
    memory_used = end_memory - start_memory
    cpu_used = end_cpu - start_cpu

    cleanup(users_created)

    # Show results
    show_results(users, messages, redis_works, results, total_time, memory_used, cpu_used)

    # Return simple hash
    {
      users: users,
      messages_per_user: messages,
      time_seconds: total_time.round(2),
      redis_working: redis_works,
      messages_sent: results[:sent],
      expected_messages: users * messages,

      success: results[:sent] == (users * messages)
    }
  end

  private

  def send_messages(users, count_per_user)
    puts "📨 Sending messages sequentially..."

    sent = 0
    failed = 0

    users.each_with_index do |user, i|
      count_per_user.times do |j|
        begin
          params = MessageParams.new(
            body: "Sequential test #{i}-#{j}",
            request_user: user
          )
          service = Messages::Operations::SendService.new(params, user)
          sent += 1 if service.call
        rescue
          failed += 1
        end
      end
    end

    puts "📨 Sent #{sent} messages (#{failed} failed)"
    puts ""
    { sent: sent, failed: failed }
  end

  def read_inboxes(users)
    read = 0
    users.each do |user|
      begin
        user.inbox.messages.limit(10).to_a
        read += 1
      rescue
        # Failed to read
      end
    end
    puts "📥 Read #{read} inboxes"
    puts ""
    read
  end

  def show_results(users, messages_per_user, redis_works, results, total_time, memory_used = 0, cpu_used = 0)
    expected = users * messages_per_user
    rate = (results[:sent] / total_time).round(1)

    puts "=" * 60
    puts "⏱️  #{total_time.round(2)}s  |  🔧 Redis/Sidekiq: #{redis_works ? '✅' : '❌'}  |  📨 #{results[:sent]}/#{expected}"
    puts ""
    puts "📈 #{rate} messages/sec (sequential)"
    puts "📅 ~#{format_capacity(rate)} messages/day capacity"
    if memory_used > 0
      memory_per_msg = memory_used / results[:sent]
      puts "💾 #{format_memory(memory_used)} memory (#{memory_per_msg.round(2)}MB per message)"
    end
    if cpu_used > 0
      cpu_percentage = (cpu_used / total_time * 100).round(1)
      cpu_cores_used = (cpu_percentage / 100.0).round(1)
      puts "💻 #{cpu_percentage}% CPU usage (~#{cpu_cores_used} cores)"
    end

    if results[:failed] > 0
      puts "⚠️  #{results[:failed]} failed"
    end

    success = results[:failed] == 0
    puts success ? "✅ All transactions completed" : "⚠️  Partial success"
    puts ""
    puts "=" * 60
    puts ""
  end


end