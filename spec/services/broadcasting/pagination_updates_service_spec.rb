# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Broadcasting::PaginationUpdatesService, type: :service do
  let(:user) { create(:user, :patient) }

  before do
    allow(Broadcasting::TurboStreamsService).to receive(:broadcast_update_to)
    allow(PaginationUpdateJob).to receive(:perform_later)
  end

  describe '.broadcast_message_pagination_update' do
    it 'returns early when user is nil' do
      described_class.broadcast_message_pagination_update(nil, :inbox)
      expect(Broadcasting::TurboStreamsService).not_to have_received(:broadcast_update_to)
    end

    it 'broadcasts inbox pagination info' do
      described_class.broadcast_message_pagination_update(user, :inbox)

      expect(Broadcasting::TurboStreamsService).to have_received(:broadcast_update_to).with(
        "inbox_#{user.inbox.id}",
        target: 'inbox-pagination-info',
        partial: 'shared/pagination_info',
        locals: { pagy: instance_of(Pagy) }
      )
    end

    it 'broadcasts outbox pagination info' do
      described_class.broadcast_message_pagination_update(user, :outbox)

      expect(Broadcasting::TurboStreamsService).to have_received(:broadcast_update_to).with(
        "user_#{user.id}_outbox",
        target: 'outbox-pagination-info',
        partial: 'shared/pagination_info',
        locals: { pagy: instance_of(Pagy) }
      )
    end

    it 'returns early for invalid list type' do
      described_class.broadcast_message_pagination_update(user, :invalid)
      expect(Broadcasting::TurboStreamsService).not_to have_received(:broadcast_update_to)
    end
  end

  describe '.broadcast_prescription_pagination_update' do
    it 'returns early when user is nil or not patient' do
      described_class.broadcast_prescription_pagination_update(nil)
      expect(Broadcasting::TurboStreamsService).not_to have_received(:broadcast_update_to)

      doctor = create(:user, :doctor)
      described_class.broadcast_prescription_pagination_update(doctor)
      expect(Broadcasting::TurboStreamsService).not_to have_received(:broadcast_update_to)
    end

    it 'broadcasts prescription pagination info for patients' do
      described_class.broadcast_prescription_pagination_update(user)

      expect(Broadcasting::TurboStreamsService).to have_received(:broadcast_update_to).with(
        "user_#{user.id}_prescriptions",
        target: 'prescriptions-pagination-info',
        partial: 'shared/pagination_info',
        locals: { pagy: instance_of(Pagy) }
      )
    end
  end

  describe '.enqueue_message_pagination_update' do
    it 'enqueues job with correct parameters' do
      described_class.enqueue_message_pagination_update(user, :inbox)
      expect(PaginationUpdateJob).to have_received(:perform_later).with(user.id, 'message', 'inbox')
    end
  end

  describe '.enqueue_prescription_pagination_update' do
    it 'enqueues job with correct parameters' do
      described_class.enqueue_prescription_pagination_update(user)
      expect(PaginationUpdateJob).to have_received(:perform_later).with(user.id, 'prescription', nil)
    end
  end
end
