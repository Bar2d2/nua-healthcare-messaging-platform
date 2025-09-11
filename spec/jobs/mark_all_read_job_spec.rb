# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarkAllReadJob, type: :job do
  let(:user) { create(:user) }
  let(:inbox) { user.inbox }

  before do
    allow(Caching::UnreadCountService).to receive(:set_unread_count)
    allow(Broadcasting::InboxUpdatesService).to receive(:broadcast_unread_count_update)
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)
  end

  describe '#perform' do
    context 'when inbox and user exist' do
      context 'with unread messages' do
        let!(:unread_messages) do
          create_list(:message, 3, inbox: inbox, read: false, status: :sent)
        end

        it 'marks all messages as read in batches' do
          described_class.perform_now(inbox.id, user.id)

          unread_messages.each do |message|
            message.reload
            expect(message.read).to be true
            expect(message.status).to eq('read')
            expect(message.read_at).to be_present
          end
        end

        it 'updates inbox unread count to 0' do
          inbox.update!(unread_count: 3) # Set initial count

          described_class.perform_now(inbox.id, user.id)

          expect(inbox.reload.unread_count).to eq(0)
        end

        it 'updates cache and broadcasts' do
          expect(Caching::UnreadCountService).to receive(:set_unread_count).with(inbox, 0)
          expect(Broadcasting::InboxUpdatesService).to receive(:broadcast_unread_count_update).with(inbox)

          described_class.perform_now(inbox.id, user.id)
        end

        it 'logs progress' do
          expect(Rails.logger).to receive(:info).with("Marking all messages as read for inbox #{inbox.id}")
          expect(Rails.logger).to receive(:info).with("Successfully marked 3 messages as read for inbox #{inbox.id}")

          described_class.perform_now(inbox.id, user.id)
        end
      end

      context 'with no unread messages' do
        it 'returns early without processing' do
          expect(Broadcasting::InboxUpdatesService).not_to receive(:broadcast_unread_count_update)

          described_class.perform_now(inbox.id, user.id)
        end
      end

      context 'with large number of messages (batching)' do
        let!(:many_messages) do
          create_list(:message, 120, inbox: inbox, read: false, status: :sent)
        end

        it 'processes messages in batches' do
          # Should process in multiple batches of 50
          expect(Broadcasting::InboxUpdatesService).to receive(:broadcast_unread_count_update).at_least(2).times

          described_class.perform_now(inbox.id, user.id)

          # All messages should be marked as read
          expect(inbox.messages.unread.count).to eq(0)
        end
      end
    end

    context 'when inbox does not exist' do
      it 'returns early without processing' do
        expect(Broadcasting::InboxUpdatesService).not_to receive(:broadcast_unread_count_update)

        described_class.perform_now('non-existent-id', user.id)
      end
    end

    context 'when user does not exist' do
      it 'returns early without processing' do
        expect(Broadcasting::InboxUpdatesService).not_to receive(:broadcast_unread_count_update)

        described_class.perform_now(inbox.id, 'non-existent-id')
      end
    end
  end
end
