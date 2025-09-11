# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Payment, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'factory' do
    it 'creates a valid payment' do
      payment = build(:payment)
      expect(payment).to be_valid
    end

    it 'creates a payment with an associated user' do
      payment = create(:payment)
      expect(payment.user).to be_present
    end
  end

  describe 'associations' do
    let(:user) { create(:user) }
    let(:payment) { create(:payment, user: user) }

    it 'belongs to a user' do
      expect(payment.user).to eq(user)
    end

    it 'can access user through association' do
      expect(payment.user.first_name).to eq(user.first_name)
    end
  end

  describe 'multiple payments' do
    let(:user) { create(:user) }
    let!(:payment1) { create(:payment, user: user) }
    let!(:payment2) { create(:payment, user: user) }

    it 'user can have multiple payments' do
      expect(user.payments.count).to eq(2)
      expect(user.payments).to include(payment1, payment2)
    end
  end
end
