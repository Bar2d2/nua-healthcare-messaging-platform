# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Messages::Operations::StatusService, type: :service do
  let(:patient) { create(:user, :patient) }
  let(:doctor) { create(:user, :doctor) }
  let(:message) { create(:message, outbox: patient.outbox, inbox: doctor.inbox, status: :sent) }
  let(:service) { described_class.new(message) }

  describe 'status validation' do
    it 'validates status transitions correctly' do
      # Sent message can transition to delivered or read
      expect(service.can_transition_to?(:delivered)).to be true
      expect(service.can_transition_to?(:read)).to be true

      # Delivered message can only transition to read
      message.update!(status: :delivered)
      service = described_class.new(message)
      expect(service.can_transition_to?(:read)).to be true
      expect(service.can_transition_to?(:sent)).to be false

      # Read message cannot transition anywhere (terminal state)
      message.update!(status: :read)
      service = described_class.new(message)
      expect(service.can_transition_to?(:sent)).to be false
      expect(service.can_transition_to?(:delivered)).to be false
    end
  end

  describe '#can_transition_to?' do
    it 'validates transitions correctly' do
      expect(service.can_transition_to?(:delivered)).to be true
      expect(service.can_transition_to?(:read)).to be true

      message.update!(status: :read)
      read_service = described_class.new(message)
      expect(read_service.can_transition_to?(:sent)).to be false
    end
  end

  describe '#available_transitions' do
    it 'returns correct transitions for each status' do
      expect(service.available_transitions).to contain_exactly(:delivered, :read)

      message.update!(status: :delivered)
      delivered_service = described_class.new(message)
      expect(delivered_service.available_transitions).to contain_exactly(:read)

      message.update!(status: :read)
      read_service = described_class.new(message)
      expect(read_service.available_transitions).to be_empty
    end
  end

  describe '.available_transitions' do
    it 'returns available transitions for message' do
      transitions = described_class.available_transitions(message)
      expect(transitions).to eq(%i[delivered read])
    end
  end

  describe '.can_transition_to?' do
    it 'validates transitions using class method' do
      expect(described_class.can_transition_to?(message, :delivered)).to be true
      expect(described_class.can_transition_to?(message, :read)).to be true
      expect(described_class.can_transition_to?(message, :sent)).to be false
    end
  end
end
