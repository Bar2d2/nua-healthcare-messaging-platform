# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Inbox, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:messages).dependent(:nullify) }
  end

  describe 'factory' do
    it 'creates a valid inbox' do
      inbox = build(:inbox)
      expect(inbox).to be_valid
    end

    it 'creates an inbox with an associated user' do
      inbox = create(:inbox)
      expect(inbox.user).to be_present
    end
  end

  describe 'associations' do
    let(:user) { create(:user) }
    let(:inbox) { create(:inbox, user: user) }
    let!(:message) { create(:message, inbox: inbox) }

    it 'belongs to a user' do
      expect(inbox.user).to eq(user)
    end

    it 'has many messages' do
      expect(inbox.messages).to include(message)
    end

    it 'nullifies messages when destroyed' do
      inbox.destroy
      message.reload
      expect(message.inbox_id).to be_nil
    end

    it 'can have multiple messages' do
      message2 = create(:message, inbox: inbox)
      expect(inbox.messages.count).to eq(2)
      expect(inbox.messages).to include(message, message2)
    end
  end

  describe 'user association' do
    let(:user) { create(:user) }
    let(:inbox) { create(:inbox, user: user) }

    it 'belongs to the correct user' do
      expect(inbox.user).to eq(user)
    end

    it 'can access user through association' do
      expect(inbox.user.first_name).to eq(user.first_name)
    end
  end
end
