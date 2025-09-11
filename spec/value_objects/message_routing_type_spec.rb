# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MessageRoutingType, type: :value_object do
  describe '.new' do
    it 'accepts string values' do
      routing_type = described_class.new('direct')
      expect(routing_type.to_s).to eq('direct')
    end

    it 'accepts symbol values' do
      routing_type = described_class.new(:reply)
      expect(routing_type.to_s).to eq('reply')
    end

    it 'raises error for invalid types' do
      expect { described_class.new('invalid') }.to raise_error(ArgumentError, /Invalid routing type/)
    end
  end

  describe 'factory methods' do
    describe '.direct' do
      it 'creates direct routing type' do
        routing_type = described_class.direct
        expect(routing_type).to be_direct
        expect(routing_type.to_s).to eq('direct')
      end
    end

    describe '.reply' do
      it 'creates reply routing type' do
        routing_type = described_class.reply
        expect(routing_type).to be_reply
        expect(routing_type.to_s).to eq('reply')
      end
    end

    describe '.auto' do
      it 'creates auto routing type' do
        routing_type = described_class.auto
        expect(routing_type).to be_auto
        expect(routing_type.to_s).to eq('auto')
      end
    end
  end

  describe '.determine_for_message' do
    let(:patient) { create(:user, :patient) }
    let(:doctor) { create(:user, :doctor) }

    it 'returns reply for messages with parent' do
      parent_message = create(:message, outbox: patient.outbox, inbox: doctor.inbox)
      child_message = create(:message, outbox: doctor.outbox, inbox: patient.inbox, parent_message: parent_message)

      routing_type = described_class.determine_for_message(child_message)
      expect(routing_type).to be_reply
    end

    it 'returns direct for messages without parent' do
      message = create(:message, outbox: patient.outbox, inbox: doctor.inbox)

      routing_type = described_class.determine_for_message(message)
      expect(routing_type).to be_direct
    end
  end

  describe 'predicate methods' do
    let(:direct_type) { described_class.new(:direct) }
    let(:reply_type) { described_class.new(:reply) }
    let(:auto_type) { described_class.new(:auto) }

    describe '#direct?' do
      it 'returns true for direct type' do
        expect(direct_type).to be_direct
        expect(reply_type).not_to be_direct
        expect(auto_type).not_to be_direct
      end
    end

    describe '#reply?' do
      it 'returns true for reply type' do
        expect(reply_type).to be_reply
        expect(direct_type).not_to be_reply
        expect(auto_type).not_to be_reply
      end
    end

    describe '#auto?' do
      it 'returns true for auto type' do
        expect(auto_type).to be_auto
        expect(direct_type).not_to be_auto
        expect(reply_type).not_to be_auto
      end
    end
  end

  describe 'comparison and conversion' do
    let(:direct1) { described_class.new(:direct) }
    let(:direct2) { described_class.new('direct') }
    let(:reply) { described_class.new(:reply) }

    describe '#==' do
      it 'compares values correctly' do
        expect(direct1).to eq(direct2)
        expect(direct1).not_to eq(reply)
      end

      it 'handles different types gracefully' do
        expect(direct1).not_to eq('direct')
        expect(direct1).not_to eq(nil)
      end
    end

    describe '#to_s' do
      it 'returns string representation' do
        expect(direct1.to_s).to eq('direct')
        expect(reply.to_s).to eq('reply')
      end
    end

    describe '#to_sym' do
      it 'returns symbol representation' do
        expect(direct1.to_sym).to eq(:direct)
        expect(reply.to_sym).to eq(:reply)
      end
    end
  end

  describe 'immutability' do
    let(:routing_type) { described_class.new(:direct) }

    it 'does not expose value setter' do
      expect(routing_type).not_to respond_to(:value=)
    end

    it 'freezes the object' do
      expect(routing_type).to be_frozen
      expect { routing_type.instance_variable_set(:@value, 'changed') }.to raise_error(FrozenError)
    end
  end
end
