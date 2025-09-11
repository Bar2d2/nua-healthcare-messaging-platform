# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Messages::Operations::UpdateService, type: :service do
  let(:message) { create(:message, status: 'sent', read: false) }
  let(:message_params) { MessageUpdateParams.new(status: 'read') }

  describe '#call' do
    context 'with valid status update' do
      it 'updates message status successfully' do
        service = described_class.new(message, message_params)
        result = service.call

        expect(result.success?).to be true
        expect(result.data.status).to eq('read')
      end
    end

    context 'with invalid status' do
      let(:invalid_params) { MessageUpdateParams.new(status: 'invalid_status') }

      it 'handles invalid status gracefully' do
        service = described_class.new(message, invalid_params)
        result = service.call

        expect(result.success?).to be false
        expect(result.error_message).to eq('Invalid status')
      end
    end

    context 'with blank status' do
      let(:blank_params) { MessageUpdateParams.new(status: '') }

      it 'filters out blank status' do
        service = described_class.new(message, blank_params)
        result = service.call

        expect(result.success?).to be true
        expect(result.data.status).to eq('sent')
      end
    end

    context 'with nil status' do
      let(:nil_params) { MessageUpdateParams.new(status: nil) }

      it 'filters out nil status' do
        service = described_class.new(message, nil_params)
        result = service.call

        expect(result.success?).to be true
        expect(result.data.status).to eq('sent')
      end
    end
  end
end
