# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MessageQuery, type: :query do
  let(:patient) { create(:user, :patient) }
  let(:doctor) { create(:user, :doctor) }

  let!(:unread_message) { create(:message, outbox: patient.outbox, inbox: doctor.inbox, read: false) }
  let!(:read_message) { create(:message, outbox: doctor.outbox, inbox: patient.inbox, read: true) }
  let!(:direct_message) { create(:message, outbox: patient.outbox, inbox: doctor.inbox, routing_type: :direct) }
  let!(:reply_message) do
    create(:message, outbox: doctor.outbox, inbox: patient.inbox, routing_type: :reply, parent_message: direct_message)
  end

  describe '#unread' do
    it 'returns only unread messages' do
      results = described_class.new.unread
      expect(results).to include(unread_message)
      expect(results).not_to include(read_message)
    end
  end

  describe '#read' do
    it 'returns only read messages' do
      results = described_class.new.read
      expect(results).to include(read_message)
      expect(results).not_to include(unread_message)
    end
  end

  describe '#by_status' do
    it 'filters by specific status' do
      sent_message = create(:message, outbox: patient.outbox, inbox: doctor.inbox, status: :sent)

      results = described_class.new.by_status(:sent)
      expect(results).to include(sent_message)
    end
  end

  describe '#by_routing_type' do
    it 'filters by routing type' do
      results = described_class.new.by_routing_type(:direct)
      expect(results).to include(direct_message)
      expect(results).not_to include(reply_message)
    end
  end

  describe '#direct_messages' do
    it 'returns only direct messages' do
      results = described_class.new.direct_messages
      expect(results).to include(direct_message)
      expect(results).not_to include(reply_message)
    end
  end

  describe '#replies' do
    it 'returns only reply messages' do
      results = described_class.new.replies
      expect(results).to include(reply_message)
      expect(results).not_to include(direct_message)
    end
  end

  describe '#recent' do
    it 'returns recent messages with default limit' do
      results = described_class.new.recent
      expect(results.count).to be <= 10
    end

    it 'respects custom limit' do
      results = described_class.new.recent(2)
      expect(results.count).to be <= 2
    end
  end

  describe '#conversation_thread' do
    it 'returns messages in the same thread' do
      results = described_class.new.conversation_thread(direct_message.id)
      expect(results).to include(direct_message, reply_message)
    end
  end

  describe '#with_conversation_users' do
    it 'includes associated users' do
      results = described_class.new.with_conversation_users
      expect(results.first.outbox.user).to be_present
      expect(results.first.inbox.user).to be_present
    end
  end

  describe 'method chaining' do
    it 'supports fluent interface' do
      results = described_class.new.unread.by_routing_type(:direct).recent(5)
      expect(results).to be_a(MessageQuery)
    end

    it 'chains multiple filters correctly' do
      unread_direct = create(:message, outbox: patient.outbox, inbox: doctor.inbox, read: false, routing_type: :direct)

      results = described_class.new.unread.direct_messages
      expect(results).to include(unread_direct)
      expect(results).not_to include(read_message)
      expect(results).not_to include(reply_message)
    end
  end

  describe 'delegation to ActiveRecord::Relation' do
    it 'delegates count' do
      expect(described_class.new.count).to eq(Message.count)
    end

    it 'delegates exists?' do
      expect(described_class.new.exists?).to be true
    end

    it 'delegates to_a' do
      results = described_class.new.to_a
      expect(results).to be_an(Array)
      expect(results.size).to eq(Message.count)
    end
  end
end
