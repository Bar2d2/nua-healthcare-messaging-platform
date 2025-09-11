# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Broadcasting::PrescriptionUpdatesService, type: :service do
  let(:user) { create(:user, :patient) }
  let(:admin) { create(:user, :admin) }
  let(:payment) { create(:payment, user: user) }
  let(:prescription) { create(:prescription, user: user, payment: payment) }

  before do
    allow(Broadcasting::TurboStreamsService).to receive(:broadcast_update_to)
    allow(Broadcasting::TurboStreamsService).to receive(:broadcast_replace_to)
    allow(Broadcasting::TurboStreamsService).to receive(:broadcast_prepend_to)
    allow(BroadcastPrescriptionUpdateJob).to receive(:perform_later)
    allow(BroadcastPrescriptionAddedJob).to receive(:perform_later)
    allow(Broadcasting::PaginationUpdatesService).to receive(:enqueue_prescription_pagination_update)
  end

  describe '.broadcast_status_update' do
    it 'returns early when prescription is nil' do
      described_class.broadcast_status_update(nil)
      expect(BroadcastPrescriptionUpdateJob).not_to have_received(:perform_later)
    end

    it 'returns early when prescription has no user' do
      prescription = build(:prescription, user: nil)
      described_class.broadcast_status_update(prescription)
      expect(BroadcastPrescriptionUpdateJob).not_to have_received(:perform_later)
    end

    it 'enqueues background job for async broadcasting' do
      described_class.broadcast_status_update(prescription, 'Test notification')

      expect(BroadcastPrescriptionUpdateJob).to have_received(:perform_later).with(
        prescription.id,
        'Test notification',
        wait_for_message_creation: false
      )
    end

    it 'supports wait_for_message option' do
      described_class.broadcast_status_update(prescription, nil, wait_for_message: true)

      expect(BroadcastPrescriptionUpdateJob).to have_received(:perform_later).with(
        prescription.id,
        nil,
        wait_for_message_creation: true
      )
    end
  end

  describe '.broadcast_status_update_sync' do
    it 'returns early when prescription is nil' do
      described_class.broadcast_status_update_sync(nil)
      expect(Broadcasting::TurboStreamsService).not_to have_received(:broadcast_replace_to)
    end

    it 'returns early when prescription has no user' do
      prescription = build(:prescription, user: nil)
      described_class.broadcast_status_update_sync(prescription)
      expect(Broadcasting::TurboStreamsService).not_to have_received(:broadcast_replace_to)
    end

    it 'broadcasts prescription item update' do
      described_class.broadcast_status_update_sync(prescription)

      expect(Broadcasting::TurboStreamsService).to have_received(:broadcast_replace_to).with(
        "user_#{user.id}_prescriptions",
        target: "prescription_#{prescription.id}",
        partial: 'prescriptions/partials/prescription_item',
        locals: { prescription: prescription }
      )
    end

    it 'broadcasts notification when provided' do
      described_class.broadcast_status_update_sync(prescription, 'Test message')

      expect(Broadcasting::TurboStreamsService).to have_received(:broadcast_update_to).with(
        "user_#{user.id}_prescriptions",
        target: 'global-notifications',
        partial: 'shared/notification',
        locals: {
          message: 'Test message',
          type: 'info',
          auto_dismiss: true
        }
      )
    end

    it 'broadcasts prescription count update' do
      described_class.broadcast_status_update_sync(prescription)

      expect(Broadcasting::TurboStreamsService).to have_received(:broadcast_update_to).with(
        "inbox_#{user.inbox.id}",
        target: 'prescription-count-badge',
        partial: 'prescriptions/partials/count_badge',
        locals: { count: user.prescriptions.count }
      )
    end
  end

  describe '.broadcast_prescription_added' do
    it 'returns early when prescription is nil' do
      described_class.broadcast_prescription_added(nil)
      expect(BroadcastPrescriptionAddedJob).not_to have_received(:perform_later)
    end

    it 'returns early when prescription has no user' do
      prescription = build(:prescription, user: nil)
      described_class.broadcast_prescription_added(prescription)
      expect(BroadcastPrescriptionAddedJob).not_to have_received(:perform_later)
    end

    it 'enqueues background job' do
      described_class.broadcast_prescription_added(prescription)
      expect(BroadcastPrescriptionAddedJob).to have_received(:perform_later).with(prescription.id)
    end
  end

  describe '.broadcast_prescription_added_sync' do
    it 'returns early when prescription is nil' do
      described_class.broadcast_prescription_added_sync(nil)
      expect(Broadcasting::TurboStreamsService).not_to have_received(:broadcast_prepend_to)
    end

    it 'prepends prescription to list' do
      described_class.broadcast_prescription_added_sync(prescription)

      expect(Broadcasting::TurboStreamsService).to have_received(:broadcast_prepend_to).with(
        "user_#{user.id}_prescriptions",
        target: 'prescriptions-items',
        partial: 'prescriptions/partials/prescription_item',
        locals: { prescription: prescription }
      )
    end

    it 'updates pagination info' do
      described_class.broadcast_prescription_added_sync(prescription)
      expect(Broadcasting::PaginationUpdatesService)
        .to have_received(:enqueue_prescription_pagination_update).with(user)
    end
  end

  describe '.broadcast_prescription_item_update' do
    it 'broadcasts item replacement' do
      described_class.send(:broadcast_prescription_item_update, prescription)

      expect(Broadcasting::TurboStreamsService).to have_received(:broadcast_replace_to).with(
        "user_#{user.id}_prescriptions",
        target: "prescription_#{prescription.id}",
        partial: 'prescriptions/partials/prescription_item',
        locals: { prescription: prescription }
      )
    end
  end

  describe '.broadcast_prescription_action_button_update' do
    let(:message) { create(:message, prescription: prescription, outbox: user.outbox, inbox: admin.inbox) }

    before do
      allow(prescription).to receive_message_chain(:messages, :first).and_return(message)
      allow(message).to receive(:conversation_root).and_return(message)
      allow(Broadcasting::TurboStreamsService).to receive(:conversation_stream).and_return('conversation_stream')
    end

    it 'returns early when prescription has no messages' do
      allow(prescription).to receive_message_chain(:messages, :first).and_return(nil)
      described_class.send(:broadcast_prescription_action_button_update, prescription)
      expect(Broadcasting::TurboStreamsService).not_to have_received(:broadcast_update_to)
    end

    it 'broadcasts both action button and badge updates' do
      described_class.send(:broadcast_prescription_action_button_update, prescription)

      expect(Broadcasting::TurboStreamsService).to have_received(:broadcast_update_to).with(
        'conversation_stream',
        target: "prescription-action-button-#{prescription.id}",
        partial: 'messages/partials/conversation/prescription_action_button',
        locals: { prescription: prescription }
      )

      expect(Broadcasting::TurboStreamsService).to have_received(:broadcast_update_to).with(
        'conversation_stream',
        target: "prescription-badge-#{prescription.id}",
        partial: 'messages/partials/conversation/prescription_badge',
        locals: { prescription: prescription }
      )
    end
  end

  describe '.broadcast_notification' do
    it 'broadcasts notification with correct parameters' do
      described_class.send(:broadcast_notification, user, 'Test notification')

      expect(Broadcasting::TurboStreamsService).to have_received(:broadcast_update_to).with(
        "user_#{user.id}_prescriptions",
        target: 'global-notifications',
        partial: 'shared/notification',
        locals: { message: 'Test notification', type: 'info', auto_dismiss: true }
      )
    end
  end

  describe '.broadcast_prescription_count_update' do
    it 'broadcasts count badge update' do
      described_class.send(:broadcast_prescription_count_update, user)

      expect(Broadcasting::TurboStreamsService).to have_received(:broadcast_update_to).with(
        "inbox_#{user.inbox.id}",
        target: 'prescription-count-badge',
        partial: 'prescriptions/partials/count_badge',
        locals: { count: user.prescriptions.count }
      )
    end
  end

  describe 'private methods' do
    describe '.prescription_stream' do
      it 'returns correct stream name' do
        stream_name = described_class.send(:prescription_stream, user)
        expect(stream_name).to eq("user_#{user.id}_prescriptions")
      end
    end

    describe '.dom_id' do
      it 'returns correct DOM ID' do
        dom_id = described_class.send(:dom_id, prescription)
        expect(dom_id).to eq("prescription_#{prescription.id}")
      end
    end
  end
end
