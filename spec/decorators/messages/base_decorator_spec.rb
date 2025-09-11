# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Messages::BaseDecorator, type: :decorator do
  let(:patient) { create(:user, :patient) }
  let(:doctor) { create(:user, :doctor) }

  let(:root_message) { create(:message, outbox: patient.outbox, inbox: doctor.inbox) }
  let(:reply_message) do
    create(:message, :reply, outbox: doctor.outbox, inbox: patient.inbox, parent_message: root_message)
  end

  let(:decorated_message) { described_class.new(reply_message) }

  describe 'initialization and delegation' do
    it 'wraps the message object' do
      expect(decorated_message.body).to eq(reply_message.body)
      expect(decorated_message.status).to eq(reply_message.status)
    end

    it 'delegates to message routing type methods' do
      expect(decorated_message.reply?).to be true
      expect(decorated_message.direct?).to be false
    end
  end

  describe 'factory methods' do
    describe '.decorate' do
      it 'creates a new decorator instance' do
        decorator = described_class.decorate(root_message)
        expect(decorator).to be_a(described_class)
        expect(decorator.id).to eq(root_message.id)
      end
    end

    describe '.decorate_collection' do
      it 'decorates an array of messages' do
        messages = [root_message, reply_message]
        decorators = described_class.decorate_collection(messages)

        expect(decorators).to all(be_a(described_class))
        expect(decorators.map(&:id)).to eq(messages.map(&:id))
      end
    end
  end

  describe 'cross-module integration' do
    it 'view methods can access conversation data' do
      # View methods use conversation data
      html = decorated_message.conversation_history_html
      expect(html).to include(decorated_message.conversation_root.body)
    end

    it 'navigation uses message context correctly' do
      request = double('request', path: '/messages/123')

      # Navigation methods work with message relationships
      expect(decorated_message.inbox_active?(patient, request)).to be true
      expect(decorated_message.outbox_active?(doctor, request)).to be true
    end
  end

  describe 'SimpleDelegator behavior' do
    it 'responds to message methods' do
      expect(decorated_message.respond_to?(:body)).to be true
      expect(decorated_message.respond_to?(:status)).to be true
      expect(decorated_message.respond_to?(:created_at)).to be true
    end

    it 'passes unknown methods to the wrapped message' do
      expect(decorated_message.inbox_id).to eq(reply_message.inbox_id)
      expect(decorated_message.outbox_id).to eq(reply_message.outbox_id)
    end
  end
end
