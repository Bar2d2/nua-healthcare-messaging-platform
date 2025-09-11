# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Messages::Queries::LoaderService, type: :service do
  let(:patient) { create(:user, is_patient: true) }
  let(:doctor) { create(:user, is_doctor: true) }

  describe '.inbox_messages_for_user' do
    it 'returns inbox messages relation with proper includes and ordering' do
      message = create(:message, inbox: patient.inbox, outbox: doctor.outbox)

      relation = described_class.inbox_messages_for_user(patient)

      expect(relation).to include(message)
      expect(relation.includes_values).to include(:outbox, :parent_message, :replies)
      expect(relation.order_values.first.to_sql).to include('created_at" DESC')
    end
  end

  describe '.outbox_messages_for_user' do
    it 'returns outbox messages relation with proper includes and ordering' do
      message = create(:message, inbox: doctor.inbox, outbox: patient.outbox)

      relation = described_class.outbox_messages_for_user(patient)

      expect(relation).to include(message)
      expect(relation.includes_values).to include(:inbox, :parent_message, :replies)
      expect(relation.order_values.first.to_sql).to include('created_at" DESC')
    end
  end

  describe '.find_message_safely' do
    let(:message) { create(:message, inbox: patient.inbox, outbox: doctor.outbox) }

    it 'returns the message when found' do
      result = described_class.find_message_safely(message.id)
      expect(result).to eq(message)
    end

    it 'returns nil when message not found' do
      result = described_class.find_message_safely('nonexistent-id')
      expect(result).to be_nil
    end
  end
end
