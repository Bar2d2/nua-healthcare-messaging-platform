# frozen_string_literal: true

# Background job for cache warming operations
# Runs during low-traffic periods to improve performance
class CacheWarmingJob < ApplicationJob
  queue_as :low_priority

  def perform(warming_type = :unread_counts)
    case warming_type.to_sym
    when :unread_counts
      Caching::WarmingService.warm_unread_counts
    when :conversations
      Caching::WarmingService.warm_conversation_caches
    when :message_lists
      Caching::WarmingService.warm_message_list_caches
    when :all
      Caching::WarmingService.schedule_warming
      Caching::WarmingService.warm_conversation_caches
      Caching::WarmingService.warm_message_list_caches
    else
      Rails.logger.warn "Unknown cache warming type: #{warming_type}"
    end
  rescue StandardError => e
    Rails.logger.error "Cache warming failed: #{e.message}"
    raise e
  end
end
