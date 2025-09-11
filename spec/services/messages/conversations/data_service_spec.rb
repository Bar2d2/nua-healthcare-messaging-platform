# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Messages::Conversations::DataService, type: :service do
  let(:patient) { create(:user, :patient) }
  let(:doctor) { create(:user, :doctor) }
  let(:admin) { create(:user, :admin) }

  let(:root_message) { create(:message, outbox: patient.outbox, inbox: doctor.inbox) }
  let(:reply_message) do
    create(:message, :reply, outbox: doctor.outbox, inbox: patient.inbox, parent_message: root_message)
  end
  let(:nested_reply) do
    create(:message, :reply, outbox: patient.outbox, inbox: admin.inbox, parent_message: reply_message)
  end

  describe '#root' do
    it 'finds the root message in conversation thread' do
      expect(described_class.new(root_message).root).to eq(root_message)
      expect(described_class.new(nested_reply).root).to eq(root_message)
    end
  end

  describe '#owner' do
    it 'returns the sender of the root message' do
      expect(described_class.new(reply_message).owner).to eq(patient)
    end
  end

  describe '#messages' do
    it 'returns all messages in conversation thread ordered by creation time' do
      nested_reply
      service = described_class.new(reply_message)
      messages = service.messages

      expect(messages).to contain_exactly(root_message, reply_message, nested_reply)
      expect(messages.map(&:created_at)).to eq(messages.map(&:created_at).sort.reverse)
    end
  end

  describe '#participants' do
    it 'returns all unique users involved in conversation' do
      nested_reply
      service = described_class.new(reply_message)
      expect(service.participants).to contain_exactly(patient, doctor, admin)
    end
  end

  describe '#doctor' do
    it 'finds the doctor in conversation' do
      service = described_class.new(reply_message)
      expect(service.doctor).to eq(doctor)
    end

    it 'returns nil when no doctor in conversation' do
      patient_only_message = create(:message, outbox: patient.outbox, inbox: admin.inbox)
      service = described_class.new(patient_only_message)
      expect(service.doctor).to be_nil
    end
  end

  describe '#threaded?' do
    it 'returns true when conversation has multiple messages' do
      service = described_class.new(reply_message)
      expect(service.threaded?).to be(true)
    end

    it 'returns false when conversation has only one message' do
      service = described_class.new(root_message)
      expect(service.threaded?).to be(false)
    end
  end

  describe '#stats' do
    it 'returns conversation statistics' do
      nested_reply
      service = described_class.new(reply_message)
      stats = service.stats

      expect(stats[:message_count]).to eq(3)
      expect(stats[:participant_count]).to eq(3)
      expect(stats[:has_doctor]).to be(true)
      expect(stats[:is_threaded]).to be(true)
      expect(stats[:created_at]).to eq(root_message.created_at)
      expect(stats[:last_activity]).to be_present
    end
  end
end
