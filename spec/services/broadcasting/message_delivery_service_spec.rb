# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Broadcasting::MessageDeliveryService, type: :service do
  let(:sender) { create(:user) }
  let(:recipient) { create(:user) }
  let(:message) { create(:message, outbox: sender.outbox, inbox: recipient.inbox) }

  before do
    allow(Broadcasting::TurboStreamsService).to receive(:broadcast_prepend_to)
    allow(Broadcasting::TurboStreamsService).to receive(:broadcast_append_to)
    allow(Broadcasting::InboxUpdatesService).to receive(:broadcast_unread_count_update_with_count)
  end

  describe '.broadcast_new_message' do
    it 'broadcasts to recipient inbox' do
      expect(Broadcasting::TurboStreamsService).to receive(:broadcast_prepend_to).with(
        "inbox_#{recipient.inbox.id}",
        target: 'inbox-list',
        partial: 'messages/partials/list/received_message_item',
        locals: { message: message }
      )

      described_class.broadcast_new_message(message)
    end

    it 'broadcasts to sender outbox' do
      expect(Broadcasting::TurboStreamsService).to receive(:broadcast_prepend_to).with(
        "user_#{sender.id}_outbox",
        target: 'outbox-list',
        partial: 'messages/partials/list/sent_message_item',
        locals: { message: message }
      )

      described_class.broadcast_new_message(message)
    end

    it 'broadcasts to general messages stream' do
      expect(Broadcasting::TurboStreamsService).to receive(:broadcast_append_to).with(
        'messages',
        target: 'messages-list',
        partial: 'messages/partials/list/received_message_item',
        locals: { message: message }
      )

      described_class.broadcast_new_message(message)
    end

    it 'broadcasts to recipient inbox stream' do
      expect(Broadcasting::TurboStreamsService).to receive(:broadcast_prepend_to)
        .with(
          Broadcasting::TurboStreamsService.inbox_stream(message.recipient_user.inbox),
          target: 'inbox-list',
          partial: 'messages/partials/list/received_message_item',
          locals: { message: message }
        )

      described_class.broadcast_new_message(message)
    end

    context 'when message is a reply' do
      let(:parent_message) { create(:message) }
      let(:reply) { create(:message, parent_message: parent_message, outbox: sender.outbox, inbox: recipient.inbox) }

      before do
        allow(reply).to receive(:conversation_root).and_return(parent_message)
      end

      it 'broadcasts to conversation thread' do
        expect(Broadcasting::TurboStreamsService).to receive(:broadcast_prepend_to).with(
          "conversation_#{parent_message.id}",
          target: 'conversation-thread',
          partial: 'messages/partials/conversation/message',
          locals: { message: reply }
        )

        described_class.broadcast_new_message(reply)
      end
    end
  end
end
