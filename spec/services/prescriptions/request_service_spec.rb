# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Prescriptions::RequestService, type: :service do
  let(:user) { create(:user, :patient) }
  let(:service) { described_class.new(user) }

  before do
    allow(PrescriptionPaymentJob).to receive(:perform_later)
  end

  describe '#call' do
    it 'creates payment and prescription successfully' do
      result = service.call

      expect(result.success?).to be true
      expect(result.data[:prescription]).to be_a(Prescription)
      expect(result.data[:payment]).to be_a(Payment)
      expect(result.data[:message]).to eq(I18n.t('prescriptions.notices.created'))
    end

    it 'creates payment with correct amount' do
      service.call

      expect(service.payment.amount).to be > 0
      expect(service.payment.user).to eq(user)
    end

    it 'creates prescription associated with payment' do
      service.call

      expect(service.prescription.user).to eq(user)
      expect(service.prescription.payment).to eq(service.payment)
      expect(service.prescription.status).to eq('requested')
    end

    it 'enqueues payment processing job' do
      service.call
      expect(PrescriptionPaymentJob).to have_received(:perform_later).with(service.payment.id)
    end

    it 'handles errors gracefully' do
      allow(Payment).to receive(:create!).and_raise(StandardError.new('Database error'))

      result = service.call

      expect(result.success?).to be false
      expect(result.error_message).to eq('Failed to submit prescription request')
      expect(result.error_details[:details]).to include('Database error')
    end
  end

  describe '#retry_payment' do
    let(:payment) { create(:payment, user: user, status: :failed) }
    let(:prescription) { create(:prescription, user: user, payment: payment) }

    it 'retries payment successfully' do
      result = service.retry_payment(prescription)

      expect(result.success?).to be true
      expect(result.data[:prescription]).to eq(prescription)
      expect(result.data[:payment]).to eq(payment)
    end

    it 'returns error when payment not found' do
      prescription_without_payment = create(:prescription, user: user, payment: nil)

      result = service.retry_payment(prescription_without_payment)

      expect(result.success?).to be false
      expect(result.error_message).to eq('Payment not found')
    end

    it 'returns error when payment already completed' do
      allow(payment).to receive(:completed?).and_return(true)

      result = service.retry_payment(prescription)

      expect(result.success?).to be false
      expect(result.error_message).to eq('Payment already completed')
    end

    it 'enqueues payment processing job for retry' do
      service.retry_payment(prescription)
      expect(PrescriptionPaymentJob).to have_received(:perform_later).with(payment.id)
    end

    it 'handles errors in retry gracefully' do
      allow(PrescriptionPaymentJob).to receive(:perform_later).and_raise(StandardError.new('Job error'))

      result = service.retry_payment(prescription)

      expect(result.success?).to be false
      expect(result.error_message).to eq('Failed to retry payment')
      expect(result.error_details[:details]).to include('Job error')
    end
  end
end
