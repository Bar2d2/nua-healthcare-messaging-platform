# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Messages::Participants::ExtractorService, type: :service do
  let(:patient) { create(:user, is_patient: true) }
  let(:doctor) { create(:user, is_doctor: true) }

  let(:patient_inbox) { create(:inbox, user: patient) }
  let(:patient_outbox) { create(:outbox, user: patient) }
  let(:doctor_inbox) { create(:inbox, user: doctor) }
  let(:doctor_outbox) { create(:outbox, user: doctor) }

  let(:message) { create(:message, inbox: doctor_inbox, outbox: patient_outbox) }

  describe '.from_message' do
    it 'extracts participants from single message' do
      participants = described_class.from_message(message)

      expect(participants).to contain_exactly(patient, doctor)
    end

    it 'handles nil message gracefully' do
      participants = described_class.from_message(nil)

      expect(participants).to eq([])
    end
  end

  describe '.from_messages' do
    it 'extracts unique participants from multiple messages' do
      message2 = create(:message, inbox: patient_inbox, outbox: doctor_outbox)

      participants = described_class.from_messages([message, message2])

      expect(participants).to contain_exactly(patient, doctor)
    end

    it 'handles empty array' do
      participants = described_class.from_messages([])

      expect(participants).to eq([])
    end
  end
end
