# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MessageCreationJob, type: :job do
  let(:sender) { create(:user) }
  let(:recipient) { create(:user) }
  let(:message_attributes) do
    {
      body: 'Test message for async creation',
      routing_type: 'direct',
      status: 'sent'
    }
  end
  let(:session_id) { 'test-session-123' }

  before do
    allow(Messages::Operations::SendService).to receive(:new).and_call_original
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)
  end

  describe '#perform' do
    context 'when user exists' do
      context 'when message creation succeeds' do
        let(:successful_result) { Api::ResponseResult.success(create(:message)) }

        before do
          send_service = instance_double(Messages::Operations::SendService)
          allow(Messages::Operations::SendService).to receive(:new).and_return(send_service)
          allow(send_service).to receive(:call).and_return(successful_result)
        end

        it 'creates message using SendService' do
          expect(Messages::Operations::SendService).to receive(:new)
            .with(instance_of(MessageParams), sender)

          described_class.perform_now(message_attributes, sender.id, session_id)
        end

        it 'logs success' do
          expect(Rails.logger).to receive(:info).with("Creating message in background for user #{sender.id}")
          expect(Rails.logger).to receive(:info).with(/Successfully created message .* in background/)

          described_class.perform_now(message_attributes, sender.id, session_id)
        end
      end

      context 'when message creation fails' do
        let(:failed_result) { Api::ResponseResult.failure('Validation failed', ['Body is required']) }

        before do
          send_service = instance_double(Messages::Operations::SendService)
          allow(Messages::Operations::SendService).to receive(:new).and_return(send_service)
          allow(send_service).to receive(:call).and_return(failed_result)
        end

        it 'logs failure' do
          expect(Rails.logger).to receive(:error).with('Failed to create message in background: Validation failed')

          described_class.perform_now(message_attributes, sender.id, session_id)
        end
      end

      context 'when SendService raises exception' do
        before do
          send_service = instance_double(Messages::Operations::SendService)
          allow(Messages::Operations::SendService).to receive(:new).and_return(send_service)
          allow(send_service).to receive(:call).and_raise(StandardError, 'Database connection failed')
        end

        it 'logs error and re-raises for retry' do
          expected_message = "Message creation job failed for user #{sender.id}: Database connection failed"
          expect(Rails.logger).to receive(:error).with(expected_message)

          expect { described_class.perform_now(message_attributes, sender.id, session_id) }
            .to raise_error(StandardError, 'Database connection failed')
        end
      end
    end

    context 'when user does not exist' do
      it 'returns early without processing' do
        expect(Messages::Operations::SendService).not_to receive(:new)

        described_class.perform_now(message_attributes, 'non-existent-id', session_id)
      end
    end
  end
end
