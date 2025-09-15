# Sidekiq Configuration for High-Performance Background Jobs
# Optimized for message system background processing

# Skip Sidekiq initialization during asset precompilation
unless ENV['RAILS_GROUPS'] == 'assets' || ENV['SECRET_KEY_BASE_DUMMY']
  # Environment-specific Redis configuration
  redis_config = case Rails.env
                 when 'test'
                   # Use separate test database to avoid conflicts
                   { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1') }
                 when 'development'
                   # Use default database with graceful fallback
                   { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
                 else
                   # Production configuration with Kamal accessory
                   { url: ENV.fetch('REDIS_URL', 'redis://nua-healthcare-app-redis:6379/0') }
                 end

# Test Redis connection before configuring Sidekiq
redis_available = begin
  redis_client = Redis.new(redis_config)
  redis_client.ping == 'PONG'
rescue Redis::CannotConnectError, Redis::ConnectionError
  false
ensure
  redis_client&.close
end

if redis_available
  Sidekiq.configure_server do |config|
    config.redis = redis_config

    # Performance optimizations for Sidekiq 7
    config.average_scheduled_poll_interval = 5

    # Configure queues with priorities for broadcasting
    # Include both prefixed (ActiveJob) and non-prefixed queues
    env_prefix = case Rails.env
                 when 'development'
                   'nua_messaging_development_'
                 when 'production'
                   'nua_messaging_production_'
                 else
                   ''
                 end

    config.queues = [
      "#{env_prefix}high_priority",
      "#{env_prefix}default",
      "#{env_prefix}low_priority",
      "#{env_prefix}mailers",
      'high_priority',  # Fallback for non-prefixed
      'default',
      'low_priority',
      'mailers'
    ]

    # Logging configuration
    config.logger.level = Rails.env.test? ? Logger::WARN : Logger::INFO
  end

  Sidekiq.configure_client do |config|
    config.redis = redis_config
  end

  Rails.logger.info "✅ Sidekiq configured with Redis" unless Rails.env.test?
else
  # Fallback configuration when Redis is not available
  Rails.logger.warn "⚠️ Redis not available - Sidekiq will use testing mode" unless Rails.env.test?

  # Only enable testing mode in test environment when Redis is not available
  if Rails.env.test?
    require 'sidekiq/testing'
    Sidekiq::Testing.fake!
  end
end

# Suppress Sidekiq logging in test environment
Sidekiq.logger.level = Logger::WARN if Rails.env.test?

# Suppress Sidekiq testing API warnings in development
if Rails.env.development?
  # Ensure testing API is properly disabled in development
  if defined?(Sidekiq::Testing)
    Sidekiq::Testing.disable!
  end

  # Show Sidekiq activity in development for debugging
  Sidekiq.logger.level = Logger::INFO
end
end