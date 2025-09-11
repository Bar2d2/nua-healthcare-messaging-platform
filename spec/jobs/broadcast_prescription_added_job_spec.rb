# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BroadcastPrescriptionAddedJob, type: :job do
  let(:user) { create(:user, :patient) }
  let(:prescription) { create(:prescription, user: user) }

  before do
    allow(Broadcasting::PrescriptionUpdatesService).to receive(:broadcast_prescription_added_sync)
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)
  end

  describe '#perform' do
    it 'broadcasts prescription addition when prescription exists' do
      described_class.new.perform(prescription.id)
      expect(Broadcasting::PrescriptionUpdatesService)
        .to have_received(:broadcast_prescription_added_sync).with(prescription)
    end

    it 'returns early when prescription not found' do
      described_class.new.perform('non-existent-id')
      expect(Broadcasting::PrescriptionUpdatesService).not_to have_received(:broadcast_prescription_added_sync)
    end

    it 'handles prescription without user gracefully' do
      allow(Prescription).to receive(:find_by).and_return(double('prescription', user: nil))
      described_class.new.perform('some-id')
      expect(Broadcasting::PrescriptionUpdatesService).not_to have_received(:broadcast_prescription_added_sync)
    end

    it 'logs successful broadcast' do
      described_class.new.perform(prescription.id)
      expect(Rails.logger).to have_received(:info)
        .with("Successfully broadcast prescription addition #{prescription.id}")
    end

    it 'handles errors and re-raises' do
      allow(Broadcasting::PrescriptionUpdatesService).to receive(:broadcast_prescription_added_sync)
        .and_raise(StandardError.new('Broadcast failed'))

      expect { described_class.new.perform(prescription.id) }.to raise_error(StandardError, 'Broadcast failed')
      expect(Rails.logger).to have_received(:error)
        .with("Failed to broadcast prescription addition #{prescription.id}: Broadcast failed")
    end
  end
end
