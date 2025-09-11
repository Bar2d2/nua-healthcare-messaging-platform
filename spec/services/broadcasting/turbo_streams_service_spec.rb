# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Broadcasting::TurboStreamsService, type: :service do
  let(:user) { create(:user) }
  let(:inbox) { user.inbox }

  before do
    allow(Turbo::StreamsChannel).to receive(:broadcast_append_to)
    allow(Turbo::StreamsChannel).to receive(:broadcast_prepend_to)
    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
    allow(Turbo::StreamsChannel).to receive(:broadcast_update_to)
  end

  describe '.broadcast_append_to' do
    it 'delegates to Turbo::StreamsChannel.broadcast_append_to' do
      expect(Turbo::StreamsChannel).to receive(:broadcast_append_to).with(
        'test_stream',
        target: 'test_target',
        partial: 'test_partial',
        locals: { test: 'data' }
      )

      described_class.broadcast_append_to(
        'test_stream',
        target: 'test_target',
        partial: 'test_partial',
        locals: { test: 'data' }
      )
    end
  end

  describe '.broadcast_prepend_to' do
    it 'delegates to Turbo::StreamsChannel.broadcast_prepend_to' do
      expect(Turbo::StreamsChannel).to receive(:broadcast_prepend_to).with(
        'test_stream',
        target: 'test_target',
        partial: 'test_partial',
        locals: { test: 'data' }
      )

      described_class.broadcast_prepend_to(
        'test_stream',
        target: 'test_target',
        partial: 'test_partial',
        locals: { test: 'data' }
      )
    end
  end

  describe '.broadcast_replace_to' do
    it 'delegates to Turbo::StreamsChannel.broadcast_replace_to' do
      expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).with(
        'test_stream',
        target: 'test_target',
        partial: 'test_partial',
        locals: { test: 'data' }
      )

      described_class.broadcast_replace_to(
        'test_stream',
        target: 'test_target',
        partial: 'test_partial',
        locals: { test: 'data' }
      )
    end
  end

  describe '.broadcast_update_to' do
    it 'delegates to Turbo::StreamsChannel.broadcast_update_to' do
      expect(Turbo::StreamsChannel).to receive(:broadcast_update_to).with(
        'test_stream',
        target: 'test_target',
        partial: 'test_partial',
        locals: { test: 'data' }
      )

      described_class.broadcast_update_to(
        'test_stream',
        target: 'test_target',
        partial: 'test_partial',
        locals: { test: 'data' }
      )
    end
  end

  describe 'stream naming conventions' do
    describe '.inbox_stream' do
      it 'returns correct inbox stream name' do
        expect(described_class.inbox_stream(inbox)).to eq("inbox_#{inbox.id}")
      end
    end

    describe '.outbox_stream' do
      it 'returns correct outbox stream name' do
        expect(described_class.outbox_stream(user)).to eq("user_#{user.id}_outbox")
      end
    end

    describe '.conversation_stream' do
      let(:conversation_root) { create(:message) }

      it 'returns correct conversation stream name' do
        expect(described_class.conversation_stream(conversation_root)).to eq("conversation_#{conversation_root.id}")
      end
    end

    describe '.messages_stream' do
      it 'returns correct messages stream name' do
        expect(described_class.messages_stream).to eq('messages')
      end
    end
  end
end
