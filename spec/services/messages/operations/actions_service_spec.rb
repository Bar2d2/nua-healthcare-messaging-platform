# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Messages::Operations::ActionsService, type: :service do
  let(:message) { create(:message, status: :sent, read: false) }

  describe '.mark_as_read!' do
    it 'marks message as read with timestamp' do
      expect { described_class.mark_as_read!(message) }
        .to change { message.reload.read }.from(false).to(true)
        .and change { message.reload.status }.from('sent').to('read')
        .and change { message.reload.read_at }.from(nil)
    end

    context 'when message cannot be marked as read' do
      let(:invalid_message) { create(:message, status: :read) }

      it 'raises an error' do
        expect { described_class.mark_as_read!(invalid_message) }
          .to raise_error(ArgumentError, /Cannot mark message as read/)
      end
    end
  end

  describe '.mark_as_read' do
    it 'marks message as read with timestamp' do
      result = described_class.mark_as_read(message)

      expect(result).to be_truthy
      expect(message.reload.read).to be true
      expect(message.reload.status).to eq('read')
      expect(message.reload.read_at).to be_present
    end

    context 'when message cannot be marked as read' do
      let(:invalid_message) { create(:message, status: :read) }

      it 'returns false without updating' do
        result = described_class.mark_as_read(invalid_message)
        expect(result).to be false
      end
    end
  end

  describe '.mark_as_delivered!' do
    it 'marks message as delivered' do
      expect { described_class.mark_as_delivered!(message) }
        .to change { message.reload.status }.from('sent').to('delivered')
    end

    context 'when message cannot be marked as delivered' do
      let(:invalid_message) { create(:message, status: :read) }

      it 'raises an error' do
        expect { described_class.mark_as_delivered!(invalid_message) }
          .to raise_error(ArgumentError, /Cannot mark message as delivered/)
      end
    end
  end

  describe '.mark_as_delivered' do
    it 'marks message as delivered' do
      result = described_class.mark_as_delivered(message)

      expect(result).to be_truthy
      expect(message.reload.status).to eq('delivered')
    end

    context 'when message cannot be marked as delivered' do
      let(:invalid_message) { create(:message, status: :read) }

      it 'returns false without updating' do
        result = described_class.mark_as_delivered(invalid_message)
        expect(result).to be false
      end
    end
  end

  describe '.bulk_mark_as_read' do
    let(:messages) { create_list(:message, 3, status: :sent, read: false) }

    it 'marks all valid messages as read' do
      count = described_class.bulk_mark_as_read(messages)

      expect(count).to eq(3)
      messages.each do |msg|
        msg.reload
        expect(msg.read).to be true
        expect(msg.status).to eq('read')
        expect(msg.read_at).to be_present
      end
    end
  end

  describe '.bulk_mark_as_delivered' do
    let(:messages) { create_list(:message, 3, status: :sent) }

    it 'marks all valid messages as delivered' do
      count = described_class.bulk_mark_as_delivered(messages)

      expect(count).to eq(3)
      messages.each do |msg|
        expect(msg.reload.status).to eq('delivered')
      end
    end
  end
end
