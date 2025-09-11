# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Inbox, type: :model do
  describe 'unread count management' do
    let(:user) { create(:user) }
    let(:inbox) { user.inbox }
    let(:outbox) { create(:outbox, user: create(:user, is_doctor: true)) }

    before { inbox.update!(unread_count: 0) }

    describe '#increment_unread_count!' do
      it 'increments the unread count' do
        expect { inbox.increment_unread_count! }
          .to change { inbox.reload.unread_count }.by(1)
      end

      it 'broadcasts unread count update' do
        expect(Turbo::StreamsChannel).to receive(:broadcast_update_to).twice  # unread count + mark all read button
        inbox.increment_unread_count!
      end
    end

    describe '#decrement_unread_count!' do
      before { inbox.update!(unread_count: 5) }

      it 'decrements the unread count' do
        expect { inbox.decrement_unread_count! }
          .to change { inbox.reload.unread_count }.by(-1)
      end

      it 'does not go below zero' do
        inbox.update!(unread_count: 0)
        expect { inbox.decrement_unread_count! }
          .not_to(change { inbox.reload.unread_count })
      end

      it 'broadcasts unread count update' do
        expect(Turbo::StreamsChannel).to receive(:broadcast_update_to).twice  # unread count + mark all read button
        inbox.decrement_unread_count!
      end
    end

    describe '#reset_unread_count!' do
      before { inbox.update!(unread_count: 10) }

      it 'resets unread count to zero' do
        expect { inbox.reset_unread_count! }
          .to change { inbox.reload.unread_count }.to(0)
      end

      it 'broadcasts unread count update' do
        expect(Turbo::StreamsChannel).to receive(:broadcast_update_to).twice  # unread count + mark all read button
        inbox.reset_unread_count!
      end
    end

    describe '#unread_messages?' do
      it 'returns true when unread count > 0' do
        create_list(:message, 3, inbox: inbox, outbox: outbox, read: false)
        expect(inbox.unread_messages?).to be true
      end

      it 'returns false when unread count is 0' do
        inbox.messages.update_all(read: true)
        expect(inbox.unread_messages?).to be false
      end
    end

    describe '#mark_all_as_read!' do
      let!(:unread_message1) { create(:message, inbox: inbox, outbox: outbox, read: false) }
      let!(:unread_message2) { create(:message, inbox: inbox, outbox: outbox, read: false) }
      let!(:read_message) do
        create(:message, inbox: inbox, outbox: outbox, read: true, read_at: 1.hour.ago, status: :read)
      end

      it 'marks all messages as read synchronously in test environment' do
        expect(unread_message1.reload).not_to be_read
        expect(unread_message2.reload).not_to be_read

        inbox.mark_all_as_read!

        expect(unread_message1.reload).to be_read
        expect(unread_message2.reload).to be_read
        expect(read_message.reload).to be_read # Should remain read
      end

      it 'updates unread count to zero' do
        # Set initial unread count to match actual unread messages
        inbox.update!(unread_count: 2)

        expect { inbox.mark_all_as_read! }
          .to change { inbox.reload.unread_count }.from(2).to(0)
      end
    end

    describe '#recalculate_unread_count!' do
      let!(:unread_message1) { create(:message, inbox: inbox, outbox: outbox, read: false) }
      let!(:unread_message2) { create(:message, inbox: inbox, outbox: outbox, read: false) }
      let!(:read_message) { create(:message, inbox: inbox, outbox: outbox, read: true) }

      before { inbox.update!(unread_count: 999) }

      it 'recalculates unread count from actual messages' do
        expect { inbox.recalculate_unread_count! }
          .to change { inbox.reload.unread_count }.to(2)
      end
    end
  end
end
