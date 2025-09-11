# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Messages::Queries::DataService, type: :service do
  let(:patient) { create(:user, is_patient: true) }
  let(:doctor) { create(:user, is_doctor: true) }

  describe '.paginated_user_messages' do
    it 'returns paginated inbox messages' do
      # Use the user's existing inbox/outbox created by factory
      message = create(:message, inbox: patient.inbox, outbox: doctor.outbox)

      messages = described_class.paginated_user_messages(
        patient.id,
        box_type: :inbox,
        page: 1,
        per_page: 10
      )

      expect(messages).to include(message)
    end

    it 'raises error for invalid box_type' do
      expect do
        described_class.paginated_user_messages(patient.id, box_type: :invalid)
      end.to raise_error(ArgumentError, /Invalid box_type/)
    end
  end

  describe '.unread_counts_by_user' do
    it 'returns unread counts for users' do
      # Use the existing inboxes created by the user factory
      patient.inbox.update!(unread_count: 2)

      counts = described_class.unread_counts_by_user([patient.id, doctor.id])

      expect(counts).to be_a(Hash)
      expect(counts[patient.id]).to eq(2)
      expect(counts[doctor.id]).to eq(0)
    end
  end
end
