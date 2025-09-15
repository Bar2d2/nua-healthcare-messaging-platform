# frozen_string_literal: true

# Sidekiq configuration for production performance
Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }

  # Sidekiq Enterprise features - comment out if using OSS
  # config.cron do
  #   # Cron jobs configuration
  # end

  # Performance monitoring
  if Rails.env.production?
    Rails.logger.info "✅ Sidekiq server configured with Redis"
  end

  # Memory usage optimization for production
  if Rails.env.production?
    config.death_handlers << ->(job, ex) do
      Rails.logger.error "Sidekiq job #{job['class']} failed: #{ex.message}"
    end
  end

  # Configure Redis connection pool
  config.redis = {
    url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'),
    size: ENV.fetch('SIDEKIQ_REDIS_POOL_SIZE', 10).to_i
  }

  # Error handling
  config.error_handlers << lambda do |ex, ctx_hash|
    Rails.logger.error "Sidekiq error: #{ex.message}"
    Rails.logger.error ctx_hash
  end

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
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }

  if Rails.env.production?
    Rails.logger.info "✅ Sidekiq client configured with Redis"
  end

  # Configure Redis connection pool for client
  config.redis = {
    url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'),
    size: ENV.fetch('SIDEKIQ_CLIENT_REDIS_POOL_SIZE', 5).to_i
  }
end

# Only start Sidekiq server automatically in specific environments
if defined?(Rails::Server) && Rails.env.development?
  begin
    require 'sidekiq/api'
    Sidekiq::Stats.new.processed
    Rails.logger.info "✅ Sidekiq connection verified"
  rescue Redis::CannotConnectError => e
    Rails.logger.warn "⚠️  Sidekiq Redis connection failed: #{e.message}"
    Rails.logger.warn "Starting without background job processing"
  end
end

# Performance optimization for production
if Rails.env.production?
  # Configure memory-efficient serialization
  Sidekiq.default_job_options = {
    'backtrace' => 10,  # Limit backtrace to save memory
    'retry' => 3        # Limit retries for faster failure detection
  }

  Rails.logger.info "✅ Sidekiq production optimizations applied"
end