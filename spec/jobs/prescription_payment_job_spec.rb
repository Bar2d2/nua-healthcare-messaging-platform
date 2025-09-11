# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PrescriptionPaymentJob, type: :job do
  let(:user) { create(:user, :patient) }
  let(:payment) { create(:payment, user: user) }

  before do
    allow(Payments::PaymentProviderFactory).to receive(:provider).and_return(double('provider'))
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:warn)
    allow(Rails.logger).to receive(:error)
  end

  describe '#perform' do
    let(:provider) { double('provider') }

    before do
      allow(Payments::PaymentProviderFactory).to receive(:provider).and_return(provider)
    end

    it 'returns early when payment not found' do
      described_class.new.perform('non-existent-id')
      expect(provider).not_to receive(:debit)
    end

    it 'processes payment successfully' do
      allow(provider).to receive(:debit).and_return(true)

      described_class.new.perform(payment.id)

      expect(provider).to have_received(:debit).with(payment.amount, payment_id: payment.id)
      expect(Rails.logger).to have_received(:info).with("Successfully processed payment #{payment.id}")
    end

    it 'handles payment provider errors' do
      allow(provider).to receive(:debit).and_raise(Payments::FlakyPaymentProvider::PaymentError.new('Payment failed'))

      expect { described_class.new.perform(payment.id) }.to raise_error(Payments::FlakyPaymentProvider::PaymentError)
    end

    it 'handles unexpected errors' do
      allow(provider).to receive(:debit).and_raise(StandardError.new('Unexpected error'))

      expect { described_class.new.perform(payment.id) }.to raise_error(StandardError)
      expect(Rails.logger).to have_received(:error)
        .with("Unexpected error processing payment #{payment.id}: Unexpected error")
    end
  end

  describe 'retry configuration' do
    it 'has correct queue configuration' do
      expect(described_class.queue_name).to eq('default')
    end
  end
end
