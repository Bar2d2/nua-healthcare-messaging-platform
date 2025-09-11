# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CacheWarmingJob, type: :job do
  describe '#perform' do
    it 'calls warming service for unread counts' do
      expect(Caching::WarmingService).to receive(:warm_unread_counts)
      described_class.perform_now(:unread_counts)
    end

    it 'calls warming service for conversations' do
      expect(Caching::WarmingService).to receive(:warm_conversation_caches)
      described_class.perform_now(:conversations)
    end

    it 'calls warming service for message lists' do
      expect(Caching::WarmingService).to receive(:warm_message_list_caches)
      described_class.perform_now(:message_lists)
    end

    it 'calls warming service for all types' do
      expect(Caching::WarmingService).to receive(:schedule_warming)
      expect(Caching::WarmingService).to receive(:warm_conversation_caches)
      expect(Caching::WarmingService).to receive(:warm_message_list_caches)
      described_class.perform_now(:all)
    end

    it 'defaults to unread counts' do
      expect(Caching::WarmingService).to receive(:warm_unread_counts)
      described_class.perform_now
    end
  end
end
