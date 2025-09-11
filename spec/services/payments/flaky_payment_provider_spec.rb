# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Payments::FlakyPaymentProvider do
  describe '#debit' do
    let(:provider) { described_class.new }

    before do
      # Reset counter before each test for predictable behavior
      described_class.reset!
    end

    context 'with new payments (no payment_id)' do
      it 'returns true for successful payments (1st-4th attempts)' do
        expect(provider.debit(100)).to be true
        expect(provider.debit(200)).to be true
        expect(provider.debit(300)).to be true
        expect(provider.debit(400)).to be true
      end

      it 'raises PaymentError on 5th attempt' do
        # Make 4 successful payments first
        4.times { provider.debit(100) }

        # 5th payment should fail
        expect do
          provider.debit(500)
        end.to raise_error(Payments::FlakyPaymentProvider::PaymentError, 'Payment provider temporarily unavailable')
      end

      it 'continues the pattern after failure' do
        # Make 5 payments (5th fails)
        4.times { provider.debit(100) }
        expect { provider.debit(100) }.to raise_error(Payments::FlakyPaymentProvider::PaymentError)

        # Next 4 should succeed
        expect(provider.debit(100)).to be true
        expect(provider.debit(100)).to be true
        expect(provider.debit(100)).to be true
        expect(provider.debit(100)).to be true

        # 10th should fail
        expect { provider.debit(100) }.to raise_error(Payments::FlakyPaymentProvider::PaymentError)
      end
    end

    context 'with retry payments (payment_id provided with retry_count > 0)' do
      let(:payment) { create(:payment, retry_count: 1) }

      it 'always succeeds for retry payments regardless of counter' do
        # Make 4 payments to set counter to 4
        4.times { provider.debit(100) }

        # Retry payment should succeed even though next would be 5th (failing) attempt
        expect(provider.debit(100, payment_id: payment.id)).to be true
      end

      it 'does not increment counter for retry payments' do
        # Make 4 payments
        4.times { provider.debit(100) }

        # Make a retry payment (should not increment counter)
        expect(provider.debit(100, payment_id: payment.id)).to be true

        # Next new payment should still be the 5th and fail
        expect { provider.debit(100) }.to raise_error(Payments::FlakyPaymentProvider::PaymentError)
      end
    end

    context 'with retry payments that have retry_count = 0' do
      let(:payment) { create(:payment, retry_count: 0) }

      it 'treats zero retry_count as new payment' do
        # Make 4 payments to set counter to 4
        4.times { provider.debit(100) }

        # Payment with retry_count = 0 should follow normal failure pattern
        expect { provider.debit(100, payment_id: payment.id) }.to raise_error(Payments::FlakyPaymentProvider::PaymentError)
      end
    end
  end

  describe 'PaymentError' do
    it 'is a StandardError' do
      expect(Payments::FlakyPaymentProvider::PaymentError).to be < StandardError
    end
  end

  describe '.reset!' do
    it 'resets the counter' do
      provider = described_class.new

      # Make some payments
      4.times { provider.debit(100) }

      # Reset
      described_class.reset!

      # After reset, we should be back to counter = 0
      # So next 4 should succeed, then 5th should fail
      expect(provider.debit(100)).to be true
      expect(provider.debit(100)).to be true
      expect(provider.debit(100)).to be true
      expect(provider.debit(100)).to be true

      # 5th should fail
      expect { provider.debit(100) }.to raise_error(Payments::FlakyPaymentProvider::PaymentError)
    end
  end
end
