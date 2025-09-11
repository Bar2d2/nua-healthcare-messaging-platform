# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Messages::ConversationDecorator, type: :decorator do
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

  let(:decorated_message) { Messages::BaseDecorator.new(reply_message) }

  before { nested_reply } # Ensure all messages exist

  describe '#conversation_root' do
    it 'returns the root message' do
      expect(decorated_message.conversation_root).to eq(root_message)
    end

    it 'memoizes the result' do
      expect(decorated_message.conversation_root).to be(decorated_message.conversation_root)
    end
  end

  describe '#conversation_owner' do
    it 'returns the conversation starter' do
      expect(decorated_message.conversation_owner).to eq(patient)
    end
  end

  describe '#conversation_participants' do
    it 'returns all unique participants' do
      participants = decorated_message.conversation_participants
      expect(participants).to include(patient, doctor, admin)
    end
  end

  describe '#conversation_messages' do
    it 'returns all messages in the thread' do
      messages = decorated_message.conversation_messages
      expect(messages).to include(root_message, reply_message, nested_reply)
      # Messages should be ordered newest first (descending order)
      expect(messages.map(&:created_at)).to eq(messages.map(&:created_at).sort.reverse)
    end
  end

  describe '#conversation_doctor' do
    it 'finds the doctor in the conversation' do
      expect(decorated_message.conversation_doctor).to eq(doctor)
    end
  end

  describe '#conversation_stats' do
    it 'returns conversation statistics' do
      stats = decorated_message.conversation_stats
      expect(stats).to include(
        message_count: 3,
        participant_count: 3,
        has_doctor: true
      )
    end
  end
end
