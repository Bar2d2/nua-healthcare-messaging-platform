# frozen_string_literal: true

# Base service for performance testing with shared functionality
class Performance::BaseService
  def test_redis
    return false unless $redis

    $redis.set("test", "ok", ex: 10)
    result = $redis.get("test") == "ok"
    $redis.del("test")
    result
  rescue
    false
  end

  def create_users(count, prefix = "Test")
    users = []
    count.times do |i|
      user = User.find_or_create_by(first_name: "#{prefix}#{i}") do |u|
        u.last_name = "User"
        u.is_patient = true
        u.is_doctor = false
        u.is_admin = false
      end
      users << user
    end
    puts ""
    puts "👥 Created #{users.size} users"
    users
  end

  def cleanup(users)
    users.each do |user|
      Message.joins(:inbox).where(inboxes: { user_id: user.id }).delete_all
      user.inbox&.destroy
      user.outbox&.destroy
      user.destroy
    end
  end

  def get_memory_usage
    # Get memory usage in MB
    pid = Process.pid
    memory_kb = `ps -o rss= -p #{pid}`.strip.to_i
    memory_kb / 1024.0
  rescue
    0
  end

  def get_cpu_time
    Process.times.utime + Process.times.stime
  rescue
    0
  end

  def format_memory(mb)
    if mb >= 1024
      "#{(mb / 1024.0).round(1)}GB"
    else
      "#{mb.round(1)}MB"
    end
  end

  def format_capacity(rate)
    daily = (rate * 0.5 * 86_400).to_i
    if daily >= 1_000_000
      "#{(daily / 1_000_000.0).round(1)}M"
    elsif daily >= 1_000
      "#{(daily / 1_000.0).round(0)}K"
    else
      daily.to_s
    end
  end

  # Abstract methods to be implemented by subclasses
  def send_messages(users, count_per_user)
    raise NotImplementedError, "#{self.class} must implement send_messages"
  end

  def show_results(users, messages_per_user, redis_works, results, total_time, memory_used, cpu_used)
    raise NotImplementedError, "#{self.class} must implement show_results"
  end
end
