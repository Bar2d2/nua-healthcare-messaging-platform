# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BroadcastMessageJob, type: :job do
  let(:message) { create(:message) }
  before do
    allow(Broadcasting::MessageDeliveryService).to receive(:broadcast_new_message)
  end

  describe '#perform' do
    context 'when message exists' do
      it 'broadcasts the message successfully' do
        allow(Message).to receive(:find_by).with(id: message.id.to_s).and_return(message)
        allow(Rails.logger).to receive(:info)

        expect(Broadcasting::MessageDeliveryService).to receive(:broadcast_new_message).with(message)

        described_class.perform_now(message.id)

        expect(Rails.logger).to have_received(:info).with("Broadcasting new message #{message.id} in background")
        expect(Rails.logger).to have_received(:info).with("Successfully broadcast new message #{message.id}")
      end
    end

    context 'when message does not exist' do
      it 'returns early without broadcasting' do
        allow(Message).to receive(:find_by).with(id: 'non-existent-id').and_return(nil)
        allow(Rails.logger).to receive(:info)

        expect(Broadcasting::MessageDeliveryService).not_to receive(:broadcast_new_message)

        described_class.perform_now('non-existent-id')

        expect(Rails.logger).not_to have_received(:info).with(/Broadcasting new message/)
      end
    end

    context 'when broadcasting fails' do
      it 'logs error and re-raises exception' do
        allow(Message).to receive(:find_by).with(id: message.id.to_s).and_return(message)
        allow(Broadcasting::MessageDeliveryService).to receive(:broadcast_new_message).and_raise(StandardError,
                                                                                                 'Broadcasting failed')
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:error)

        expect { described_class.perform_now(message.id) }.to raise_error(StandardError, 'Broadcasting failed')

        expect(Rails.logger).to have_received(:error)
          .with("Failed to broadcast message #{message.id}: Broadcasting failed")
      end
    end
  end
end
