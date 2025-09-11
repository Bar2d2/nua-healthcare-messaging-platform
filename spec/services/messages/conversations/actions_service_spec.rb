# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Messages::Conversations::ActionsService, type: :service do
  let(:patient) { create(:user, is_patient: true) }
  let(:doctor) { create(:user, is_doctor: true) }

  describe '.mark_conversation_as_read' do
    let(:message) { create(:message, inbox: patient.inbox, outbox: doctor.outbox) }

    context 'when user has inbox and unread messages' do
      before do
        # Set message as unread
        message.update!(read: false)
        # Mock conversation_messages to return the message
        allow(message).to receive(:conversation_messages).and_return([message])
      end

      it 'marks unread inbox messages as read' do
        expect(Messages::Operations::ActionsService).to receive(:mark_messages_as_read)
          .with([message], inbox_filter: patient.inbox)
          .and_return({ updated_count: 1, affected_inboxes: [patient.inbox] })

        described_class.mark_conversation_as_read(message, patient)
      end
    end

    context 'when user has no inbox' do
      it 'returns early without processing' do
        user_without_inbox = double('user', inbox: nil)
        expect(message).not_to receive(:conversation_messages)

        described_class.mark_conversation_as_read(message, user_without_inbox)
      end
    end

    context 'when no unread messages in user inbox' do
      before do
        # Message is for different inbox
        other_message = create(:message, inbox: doctor.inbox, outbox: patient.outbox)
        allow(message).to receive(:conversation_messages).and_return([other_message])
      end

      it 'returns early without marking anything' do
        expect_any_instance_of(Message).not_to receive(:mark_as_read!)

        described_class.mark_conversation_as_read(message, patient)
      end
    end
  end

  describe '.prepare_new_message' do
    it 'creates new message with outbox association' do
      result = described_class.prepare_new_message(nil, patient)

      expect(result).to be_a(Message)
      expect(result.outbox).to eq(patient.outbox)
      expect(result.routing_type).to eq('direct')
    end

    it 'sets reply routing type for messages with parent' do
      parent_message = create(:message, inbox: patient.inbox, outbox: doctor.outbox)

      result = described_class.prepare_new_message(parent_message.id, patient)

      expect(result.parent_message_id).to eq(parent_message.id)
      expect(result.routing_type).to eq('reply')
    end
  end

  describe '.determine_recipient_for_message' do
    let(:message) { Message.new }
    let(:routing_service) { double('routing_service') }

    context 'when message has no parent (new message)' do
      before do
        allow(Messages::Operations::RoutingService).to receive(:new).and_return(routing_service)
        allow(routing_service).to receive(:determine_recipient).and_return(doctor)
      end

      it 'determines recipient using routing service' do
        result = described_class.determine_recipient_for_message(message, patient)

        expect(Messages::Operations::RoutingService).to have_received(:new).with(message, patient)
        expect(result).to eq(doctor)
      end
    end

    context 'when message has parent (reply)' do
      let(:parent_message) { create(:message, inbox: patient.inbox, outbox: doctor.outbox) }

      before do
        message.parent_message_id = parent_message.id
        allow(Messages::Operations::RoutingService).to receive(:new)
      end

      it 'returns nil for replies' do
        result = described_class.determine_recipient_for_message(message, patient)

        expect(result).to be_nil
        expect(Messages::Operations::RoutingService).not_to have_received(:new)
      end
    end

    context 'when routing service raises exception' do
      before do
        allow(Messages::Operations::RoutingService).to receive(:new).and_return(routing_service)
        allow(routing_service).to receive(:determine_recipient)
          .and_raise(Messages::Operations::RoutingService::NoDoctorAvailableError)
      end

      it 'returns nil when routing fails' do
        result = described_class.determine_recipient_for_message(message, patient)

        expect(result).to be_nil
      end
    end
  end
end
