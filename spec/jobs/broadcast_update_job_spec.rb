# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BroadcastUpdateJob, type: :job do
  let(:message) { create(:message) }
  before do
    allow(Broadcasting::MessageStatusService).to receive(:broadcast_status_update)
  end

  describe '#perform' do
    context 'when message exists' do
      it 'broadcasts the update successfully' do
        allow(Message).to receive(:find_by).with(id: message.id.to_s).and_return(message)
        allow(Rails.logger).to receive(:info)

        expect(Broadcasting::MessageStatusService).to receive(:broadcast_status_update).with(message)

        described_class.perform_now(message.id)

        expect(Rails.logger).to have_received(:info).with("Broadcasting message update #{message.id} in background")
        expect(Rails.logger).to have_received(:info).with("Successfully broadcast message update #{message.id}")
      end
    end

    context 'when message does not exist' do
      it 'returns early without broadcasting' do
        allow(Message).to receive(:find_by).with(id: 'non-existent-id').and_return(nil)
        allow(Rails.logger).to receive(:info)

        expect(Broadcasting::MessageStatusService).not_to receive(:broadcast_status_update)

        described_class.perform_now('non-existent-id')

        expect(Rails.logger).not_to have_received(:info).with(/Broadcasting message update/)
      end
    end

    context 'when broadcasting fails' do
      it 'logs error and re-raises exception' do
        allow(Message).to receive(:find_by).with(id: message.id.to_s).and_return(message)
        allow(Broadcasting::MessageStatusService).to receive(:broadcast_status_update).and_raise(StandardError,
                                                                                                 'Broadcasting failed')
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:error)

        expect { described_class.perform_now(message.id) }.to raise_error(StandardError, 'Broadcasting failed')

        expect(Rails.logger).to have_received(:error)
          .with("Failed to broadcast message update #{message.id}: Broadcasting failed")
      end
    end
  end
end
