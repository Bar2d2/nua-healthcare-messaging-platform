# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UnreadCountUpdateJob, type: :job do
  let(:inbox) { create(:inbox) }

  before do
    allow(Inboxes::Operations::ActionsService).to receive(:increment!)
    allow(Inboxes::Operations::ActionsService).to receive(:decrement!)
    allow(Inboxes::Operations::ActionsService).to receive(:reset!)
    allow(Inboxes::Operations::ActionsService).to receive(:set!)
    allow(Inboxes::Operations::ActionsService).to receive(:recalculate!)
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)
  end

  describe '#perform' do
    context 'when inbox exists' do
      describe 'increment operation' do
        it 'calls increment service' do
          expect(Inboxes::Operations::ActionsService).to receive(:increment!).with(inbox)

          described_class.perform_now(inbox.id, 'increment')

          expect(Rails.logger).to have_received(:info).with("Updating unread count for inbox #{inbox.id}: increment")
          expect(Rails.logger).to have_received(:info).with("Successfully updated unread count for inbox #{inbox.id}")
        end
      end

      describe 'decrement operation' do
        it 'calls decrement service' do
          expect(Inboxes::Operations::ActionsService).to receive(:decrement!).with(inbox)

          described_class.perform_now(inbox.id, 'decrement')
        end
      end

      describe 'reset operation' do
        it 'calls reset service' do
          expect(Inboxes::Operations::ActionsService).to receive(:reset!).with(inbox)

          described_class.perform_now(inbox.id, 'reset')
        end
      end

      describe 'set operation' do
        it 'calls set service with count' do
          expect(Inboxes::Operations::ActionsService).to receive(:set!).with(inbox, 5)

          described_class.perform_now(inbox.id, 'set', 5)
        end
      end

      describe 'recalculate operation' do
        it 'calls recalculate service' do
          expect(Inboxes::Operations::ActionsService).to receive(:recalculate!).with(inbox)

          described_class.perform_now(inbox.id, 'recalculate')
        end
      end

      describe 'unknown operation' do
        it 'logs error for unknown operation' do
          expect(Rails.logger).to receive(:error).with('Unknown unread count operation: invalid')

          described_class.perform_now(inbox.id, 'invalid')
        end
      end
    end

    context 'when inbox does not exist' do
      it 'returns early without processing' do
        expect(Inboxes::Operations::ActionsService).not_to receive(:increment!)

        described_class.perform_now('non-existent-id', 'increment')
      end
    end

    context 'when operation fails' do
      it 'logs error and does not re-raise' do
        allow(Inboxes::Operations::ActionsService).to receive(:increment!).and_raise(StandardError, 'Test error')

        expect(Rails.logger).to receive(:error).with("Failed to update unread count for inbox #{inbox.id}: Test error")

        expect { described_class.perform_now(inbox.id, 'increment') }.not_to raise_error
      end
    end
  end
end
