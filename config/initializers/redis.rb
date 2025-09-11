# frozen_string_literal: true

# Redis Configuration for High-Performance Caching and Background Jobs
# Optimized for message system scalability

# Environment-specific Redis configuration
REDIS_URL = case Rails.env
            when 'test'
              ENV.fetch('REDIS_URL', 'redis://localhost:6379/2') # Separate test DB
            when 'development'
              ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') # Default DB
            else
              ENV.fetch('REDIS_URL') # Production requires explicit URL
            end

# Configure Redis connection pool for performance
begin
  $redis = Redis.new(
    url: REDIS_URL,
    timeout: 1,           # Connection timeout
    reconnect_attempts: 3  # Retry connection
  )

  # Test connection
  $redis.ping
  Rails.logger.info "✅ Redis connected successfully (#{Rails.env})" unless Rails.env.test?
rescue Redis::CannotConnectError, Redis::ConnectionError => e
  Rails.logger.error "❌ Redis connection failed: #{e.message}" unless Rails.env.test?

  # Environment-specific fallback behavior
  case Rails.env
  when 'production'
    # Fail fast in production
    raise e
  when 'test'
    # Silent fallback in test (performance benchmarks will handle gracefully)
    $redis = nil
  else
    # Development continues without Redis
    Rails.logger.warn "⚠️ Continuing without Redis in #{Rails.env} environment" unless Rails.env.test?
    $redis = nil
  end
end

# Add Redis health check method
def redis_available?
  return false unless $redis

  $redis.ping == 'PONG'
rescue Redis::CannotConnectError, Redis::ConnectionError
  false
end
