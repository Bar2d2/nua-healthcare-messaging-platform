# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BroadcastPrescriptionUpdateJob, type: :job do
  let(:user) { create(:user, :patient) }
  let(:prescription) { create(:prescription, user: user) }

  before do
    allow(Broadcasting::PrescriptionUpdatesService).to receive_messages(
      broadcast_prescription_item_update: nil,
      broadcast_prescription_action_button_update: nil,
      broadcast_notification: nil,
      broadcast_prescription_count_update: nil
    )
    allow(Broadcasting::PaginationUpdatesService).to receive(:enqueue_prescription_pagination_update)
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)
  end

  describe '#perform' do
    it 'broadcasts all updates when prescription exists' do
      described_class.new.perform(prescription.id)

      expect(Broadcasting::PaginationUpdatesService)
        .to have_received(:enqueue_prescription_pagination_update).with(user)
    end

    it 'returns early when prescription not found' do
      described_class.new.perform('non-existent-id')
      expect(Broadcasting::PaginationUpdatesService).not_to have_received(:enqueue_prescription_pagination_update)
    end

    it 'waits for message creation when requested' do
      allow_any_instance_of(described_class).to receive(:sleep)

      described_class.new.perform(prescription.id, nil, wait_for_message_creation: true)

      expect(Rails.logger).to have_received(:info)
        .with("Waited for message creation before broadcasting prescription #{prescription.id}")
    end

    it 'broadcasts notification when provided' do
      described_class.new.perform(prescription.id, 'Test notification')
      expect(Rails.logger).to have_received(:info)
        .with("Successfully broadcast prescription update #{prescription.id} in logical order")
    end

    it 'handles errors and re-raises' do
      allow(Broadcasting::PaginationUpdatesService).to receive(:enqueue_prescription_pagination_update)
        .and_raise(StandardError.new('Update failed'))

      expect { described_class.new.perform(prescription.id) }.to raise_error(StandardError, 'Update failed')
      expect(Rails.logger).to have_received(:error)
        .with("Failed to broadcast prescription update #{prescription.id}: Update failed")
    end
  end
end
