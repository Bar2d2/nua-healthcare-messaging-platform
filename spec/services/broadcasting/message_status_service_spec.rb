# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Broadcasting::MessageStatusService, type: :service do
  let(:sender) { create(:user) }
  let(:recipient) { create(:user) }
  let(:message) { create(:message, outbox: sender.outbox, inbox: recipient.inbox) }

  before do
    allow(Broadcasting::TurboStreamsService).to receive(:broadcast_replace_to)
  end

  describe '.broadcast_status_update' do
    it 'broadcasts status update to recipient inbox' do
      message_id = ActionView::RecordIdentifier.dom_id(message)

      expect(Broadcasting::TurboStreamsService).to receive(:broadcast_replace_to).with(
        "inbox_#{recipient.inbox.id}",
        target: message_id,
        partial: 'messages/partials/list/received_message_item',
        locals: { message: message }
      )

      described_class.broadcast_status_update(message)
    end

    context 'when message is a reply' do
      let(:parent_message) { create(:message) }
      let(:reply) { create(:message, parent_message: parent_message, outbox: sender.outbox, inbox: recipient.inbox) }

      before do
        allow(reply).to receive(:conversation_root).and_return(parent_message)
      end

      it 'broadcasts status update to conversation thread' do
        message_id = ActionView::RecordIdentifier.dom_id(reply)

        expect(Broadcasting::TurboStreamsService).to receive(:broadcast_replace_to).with(
          "conversation_#{parent_message.id}",
          target: message_id,
          partial: 'messages/partials/conversation/message',
          locals: { message: reply }
        )

        described_class.broadcast_status_update(reply)
      end

      it 'broadcasts to both recipient inbox and conversation thread' do
        message_id = ActionView::RecordIdentifier.dom_id(reply)

        # Should broadcast to recipient inbox
        expect(Broadcasting::TurboStreamsService).to receive(:broadcast_replace_to).with(
          "inbox_#{recipient.inbox.id}",
          target: message_id,
          partial: 'messages/partials/list/received_message_item',
          locals: { message: reply }
        )

        # Should broadcast to conversation thread
        expect(Broadcasting::TurboStreamsService).to receive(:broadcast_replace_to).with(
          "conversation_#{parent_message.id}",
          target: message_id,
          partial: 'messages/partials/conversation/message',
          locals: { message: reply }
        )

        described_class.broadcast_status_update(reply)
      end
    end

    context 'when recipient user is nil' do
      before do
        allow(message).to receive(:recipient_user).and_return(nil)
      end

      it 'does not broadcast to recipient inbox' do
        expect(Broadcasting::TurboStreamsService).not_to receive(:broadcast_replace_to)

        described_class.broadcast_status_update(message)
      end
    end
  end

  describe '#broadcast_status_update (instance method)' do
    let(:service) { described_class.new(message) }

    it 'broadcasts status update using instance method' do
      message_id = ActionView::RecordIdentifier.dom_id(message)

      expect(Broadcasting::TurboStreamsService).to receive(:broadcast_replace_to).with(
        "inbox_#{recipient.inbox.id}",
        target: message_id,
        partial: 'messages/partials/list/received_message_item',
        locals: { message: message }
      )

      service.broadcast_status_update
    end
  end
end
