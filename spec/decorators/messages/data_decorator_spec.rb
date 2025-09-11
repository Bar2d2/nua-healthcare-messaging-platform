# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Messages::DataDecorator, type: :decorator do
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

  before { nested_reply }

  describe '#conversation_thread_count' do
    it 'returns the number of messages in the thread' do
      expect(decorated_message.conversation_thread_count).to eq(3)
    end
  end

  describe '#conversation_last_activity' do
    it 'returns the timestamp of the last message' do
      expect(decorated_message.conversation_last_activity).to eq(nested_reply.created_at)
    end
  end

  describe '#conversation_has_unread?' do
    it 'returns true when there are unread messages' do
      nested_reply.update!(read: false)
      expect(decorated_message.conversation_has_unread?).to be true
    end

    it 'returns false when all messages are read' do
      root_message.update!(read: true)
      reply_message.update!(read: true)
      nested_reply.update!(read: true)
      expect(decorated_message.conversation_has_unread?).to be false
    end
  end

  describe '#conversation_duration' do
    it 'calculates time between first and last message' do
      # Simulate time passage
      nested_reply.update!(created_at: root_message.created_at + 1.hour)

      duration = decorated_message.conversation_duration
      expect(duration).to be_within(1.second).of(1.hour)
    end

    it 'returns 0 for single message conversations' do
      single_message = create(:message, outbox: patient.outbox, inbox: doctor.inbox)
      decorated_single = Messages::BaseDecorator.new(single_message)

      expect(decorated_single.conversation_duration).to eq(0)
    end
  end
end
