# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Outbox, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:messages).dependent(:destroy) }
  end

  describe 'factory' do
    it 'creates a valid outbox' do
      outbox = build(:outbox)
      expect(outbox).to be_valid
    end

    it 'creates an outbox with an associated user' do
      outbox = create(:outbox)
      expect(outbox.user).to be_present
    end
  end

  describe 'associations' do
    let(:user) { create(:user) }
    let(:outbox) { create(:outbox, user: user) }
    let!(:message) { create(:message, outbox: outbox) }

    it 'belongs to a user' do
      expect(outbox.user).to eq(user)
    end

    it 'has many messages' do
      expect(outbox.messages).to include(message)
    end

    it 'destroys messages when destroyed' do
      expect { outbox.destroy }.to change(Message, :count).by(-1)
    end

    it 'can have multiple messages' do
      message2 = create(:message, outbox: outbox)
      expect(outbox.messages.count).to eq(2)
      expect(outbox.messages).to include(message, message2)
    end
  end

  describe 'user association' do
    let(:user) { create(:user) }
    let(:outbox) { create(:outbox, user: user) }

    it 'belongs to the correct user' do
      expect(outbox.user).to eq(user)
    end

    it 'can access user through association' do
      expect(outbox.user.first_name).to eq(user.first_name)
    end
  end
end
