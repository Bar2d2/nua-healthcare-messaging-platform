# frozen_string_literal: true

desc 'Performance testing: sequential and concurrent'
namespace :performance_check do

  task :sequential, %i[users messages] => :environment do |_t, args|
    users = (args[:users] || 10).to_i
    messages = (args[:messages] || 5).to_i

    setup_real_sidekiq
    results = Performance::SequentialExecutionService.run(users: users, messages: messages)
    exit(results[:success] ? 0 : 1)
  end

  task :concurrent, %i[users messages] => :environment do |_t, args|
    users = (args[:users] || 10).to_i
    messages = (args[:messages] || 5).to_i

    setup_real_sidekiq
    results = Performance::ConcurrentExecutionService.run(users: users, messages: messages)
    exit(results[:success] ? 0 : 1)
  end

  def setup_real_sidekiq
    # Force real background processing
    if defined?(Sidekiq::Testing)
      Sidekiq::Testing.disable!
    end

    # Suppress Sidekiq logs during performance testing
    if defined?(Sidekiq)
      Sidekiq.logger.level = Logger::ERROR
    end

    # Ensure Redis is available
    unless $redis
      puts "❌ Redis not available - performance tests require Redis"
      exit(1)
    end

  rescue => e
    puts "📡 Redis error: #{e.message}"
    exit(1)
  end
end

# Simple aliases
task :sequential, %i[users messages] => 'performance_check:sequential'
task :concurrent, %i[users messages] => 'performance_check:concurrent'

# Default to sequential
task :perform, %i[users messages] => 'performance_check:sequential'

# Examples:
# rake sequential[20,10]    # Sequential: 20 users, 10 messages
# rake concurrent[5,3]      # Concurrent: 5 users, 3 messages
# rake perform[15,8]        # Default sequential
