# frozen_string_literal: true

# Concurrent performance check for Redis + Sidekiq + Database
class Performance::ConcurrentExecutionService < Performance::BaseService
  def self.run(users: 5, messages: 2)
    new.check(users, messages)
  end

  def check(users, messages)
    puts ""
    puts "🔥 CONCURRENT Performance Check: #{users} users × #{messages} message(s) per user"
    puts "   (Note: Tests simultaneous operations with threading)"
    puts "=" * 60

    start_time = Time.current
    start_memory = get_memory_usage
    start_cpu = get_cpu_time

    # What we're testing
    redis_works = test_redis
    users_created = create_users(users, "Concurrent")
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
      messages_failed: results[:failed],
      concurrent_rate: results[:rate],
      success: results[:failed] == 0
    }
  end

  private

  def send_messages(users, count_per_user)
    puts "⚡ Sending messages concurrently..."

    start_time = Time.current
    sent = 0
    threads = []

    # Each user sends messages in their own thread
    users.each_with_index do |user, i|
      threads << Thread.new do
        thread_sent = 0
        count_per_user.times do |j|
          params = MessageParams.new(
            body: "Concurrent test #{i}-#{j}",
            request_user: user
          )
          service = Messages::Operations::SendService.new(params, user)
          thread_sent += 1 if service.call
        rescue
          # Failed to send
        end
        Thread.current[:sent] = thread_sent
      end
    end

    # Wait for all threads
    threads.each(&:join)

    # Collect results
    threads.each { |thread| sent += thread[:sent] || 0 }

    failed = (users.size * count_per_user) - sent
    time_taken = Time.current - start_time
    rate = sent / time_taken.to_f

    puts "📨 Sent #{sent} messages (#{failed} failed)"

    { sent: sent, failed: failed, rate: rate.round(1) }
  end

  def show_results(users, messages_per_user, redis_works, results, total_time, memory_used = 0, cpu_used = 0)
    expected = users * messages_per_user
    puts ""
    puts "=" * 60
    puts "⏱️  #{total_time.round(2)}s  |  🔧 Redis/Sidekiq: #{redis_works ? '✅' : '❌'}  |  📨 #{results[:sent]}/#{expected}"
    puts ""
    puts "📨 #{results[:rate]} messages/sec (concurrent)"
    puts "📅 ~#{format_capacity(results[:rate])} messages/day capacity"
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
      puts "⚠️  #{results[:failed]} failed (database locking)"
    end

    success = results[:failed] == 0
    puts success ? "✅ All transactions completed" : "⚠️  Partial success"
    puts ""
    puts "=" * 60
    puts ""
  end


end