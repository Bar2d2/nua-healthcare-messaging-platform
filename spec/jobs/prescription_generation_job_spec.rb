# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PrescriptionGenerationJob, type: :job do
  let(:user) { create(:user, :patient) }
  let(:admin) { create(:user, :admin) }
  let(:prescription) { create(:prescription, user: user) }

  before do
    allow(Broadcasting::PrescriptionUpdatesService).to receive(:broadcast_status_update)
    allow(MessageCreationJob).to receive(:perform_later)
    allow(User).to receive_message_chain(:admin, :first).and_return(admin)
  end

  describe '#perform' do
    it 'marks prescription as ready and generates PDF URL' do
      described_class.new.perform(prescription.id)

      prescription.reload
      expect(prescription.status).to eq('ready')
      expect(prescription.pdf_url).to include('example.com/prescriptions')
    end

    it 'returns early when prescription not found' do
      described_class.new.perform('non-existent-id')
      expect(MessageCreationJob).not_to have_received(:perform_later)
    end

    it 'broadcasts status update after message creation' do
      described_class.new.perform(prescription.id)

      expect(Broadcasting::PrescriptionUpdatesService).to have_received(:broadcast_status_update)
        .with(prescription, nil, wait_for_message: true)
    end

    it 'creates reply message when original message provided' do
      described_class.new.perform(prescription.id, 'message-123')

      expect(MessageCreationJob).to have_received(:perform_later) do |message_params, admin_id, _|
        expect(message_params[:routing_type]).to eq('reply')
        expect(message_params[:parent_message_id]).to eq('message-123')
        expect(admin_id).to eq(admin.id)
      end
    end

    it 'creates direct message when no original message' do
      described_class.new.perform(prescription.id)

      expect(MessageCreationJob).to have_received(:perform_later) do |message_params, admin_id, _|
        expect(message_params[:routing_type]).to eq('direct')
        expect(admin_id).to eq(admin.id)
      end
    end

    it 'returns early when no admin available' do
      allow(User).to receive_message_chain(:admin, :first).and_return(nil)

      described_class.new.perform(prescription.id)
      expect(MessageCreationJob).not_to have_received(:perform_later)
    end
  end
end
