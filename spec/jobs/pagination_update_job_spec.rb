# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaginationUpdateJob, type: :job do
  let(:user) { create(:user, :patient) }

  before do
    allow(Broadcasting::PaginationUpdatesService).to receive(:broadcast_message_pagination_update)
    allow(Broadcasting::PaginationUpdatesService).to receive(:broadcast_prescription_pagination_update)
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)
  end

  describe '#perform' do
    it 'returns early when user does not exist' do
      described_class.new.perform('non-existent-id', 'message', 'inbox')
      expect(Broadcasting::PaginationUpdatesService).not_to have_received(:broadcast_message_pagination_update)
    end

    it 'calls message pagination update service' do
      described_class.new.perform(user.id, 'message', 'inbox')
      expect(Broadcasting::PaginationUpdatesService).to have_received(:broadcast_message_pagination_update).with(user,
                                                                                                                 :inbox)
    end

    it 'calls prescription pagination update service' do
      described_class.new.perform(user.id, 'prescription', nil)
      expect(Broadcasting::PaginationUpdatesService).to have_received(:broadcast_prescription_pagination_update)
        .with(user)
    end

    it 'logs successful updates' do
      described_class.new.perform(user.id, 'message', 'inbox')
      expected_message = "Updated pagination for user #{user.id}, type: message, list: inbox"
      expect(Rails.logger).to have_received(:info).with(expected_message)
    end

    it 'handles errors gracefully' do
      allow(User).to receive(:find_by).and_raise(StandardError.new('Database error'))

      expect { described_class.new.perform(user.id, 'message', 'inbox') }.not_to raise_error
      expect(Rails.logger).to have_received(:error).with("Pagination update failed for user #{user.id}: Database error")
    end
  end
end
