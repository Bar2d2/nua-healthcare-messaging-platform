# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Broadcasting::InboxUpdatesService, type: :service do
  let(:user) { create(:user) }
  let(:inbox) { user.inbox }

  before do
    allow(Broadcasting::TurboStreamsService).to receive(:broadcast_update_to)
  end

  describe '.broadcast_unread_count_update' do
    it 'broadcasts unread count update to correct stream' do
      expect(Broadcasting::TurboStreamsService).to receive(:broadcast_update_to).with(
        "inbox_#{inbox.id}",
        target: "inbox_unread_count_#{inbox.id}",
        partial: 'inboxes/unread_count',
        locals: { inbox: inbox }
      )

      described_class.broadcast_unread_count_update(inbox)
    end

    it 'automatically broadcasts mark all read button update' do
      expect(described_class).to receive(:broadcast_mark_all_read_button_update).with(user)

      described_class.broadcast_unread_count_update(inbox)
    end

    context 'when inbox is nil' do
      it 'returns early without broadcasting' do
        expect(Broadcasting::TurboStreamsService).not_to receive(:broadcast_update_to)

        described_class.broadcast_unread_count_update(nil)
      end
    end

    context 'when user is nil' do
      let(:inbox_without_user) { double('inbox', user: nil) }

      it 'returns early without broadcasting' do
        expect(Broadcasting::TurboStreamsService).not_to receive(:broadcast_update_to)

        described_class.broadcast_unread_count_update(inbox_without_user)
      end
    end
  end

  describe '.broadcast_unread_count_update_with_count' do
    let(:count) { 5 }

    it 'broadcasts unread count with specific count' do
      expect(Broadcasting::TurboStreamsService).to receive(:broadcast_update_to).with(
        "inbox_#{inbox.id}",
        target: "inbox_unread_count_#{inbox.id}",
        partial: 'inboxes/unread_count',
        locals: { inbox: inbox, unread_count: count }
      )

      described_class.broadcast_unread_count_update_with_count(user, count)
    end
  end

  describe '.broadcast_mark_all_read_button_update' do
    it 'broadcasts mark all read button update' do
      expect(Broadcasting::TurboStreamsService).to receive(:broadcast_update_to).with(
        "inbox_#{inbox.id}",
        target: 'mark_all_read_button',
        partial: 'messages/partials/mark_all_read_button',
        locals: { inbox: inbox }
      )

      described_class.broadcast_mark_all_read_button_update(user)
    end
  end
end
