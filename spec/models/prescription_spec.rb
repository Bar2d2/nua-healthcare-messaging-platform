# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Prescription, type: :model do
  let(:user) { create(:user, :patient) }
  let(:payment) { create(:payment) }

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:payment).optional }
    it { should have_many(:messages).dependent(:nullify) }
  end

  describe 'validations' do
    it { should validate_presence_of(:requested_at) }

    context 'when ready' do
      subject { build(:prescription, :ready) }
      it { should validate_presence_of(:pdf_url) }
      it { should validate_presence_of(:ready_at) }
    end
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(requested: 0, payment_rejected: 1, ready: 2) }
  end

  describe 'scopes' do
    let!(:old_prescription) { create(:prescription, user: user, created_at: 2.days.ago) }
    let!(:new_prescription) { create(:prescription, user: user, created_at: 1.day.ago) }

    it 'orders by recent first' do
      expect(Prescription.recent).to eq([new_prescription, old_prescription])
    end

    it 'filters by user' do
      other_user = create(:user, :patient)
      create(:prescription, user: other_user)

      expect(Prescription.for_user(user)).to contain_exactly(old_prescription, new_prescription)
    end
  end

  describe '#downloadable?' do
    it 'returns true when ready with pdf_url' do
      prescription = build(:prescription, :ready)
      expect(prescription.downloadable?).to be true
    end

    it 'returns false when not ready' do
      prescription = build(:prescription, :requested)
      expect(prescription.downloadable?).to be false
    end
  end

  describe '#retryable?' do
    it 'returns true when payment rejected and payment failed' do
      failed_payment = create(:payment, :failed)
      prescription = create(:prescription, :payment_rejected, payment: failed_payment)
      expect(prescription.retryable?).to be true
    end

    it 'returns false when not payment rejected' do
      prescription = create(:prescription, :requested)
      expect(prescription.retryable?).to be false
    end
  end

  describe '#processing?' do
    it 'returns true when requested with pending payment' do
      pending_payment = create(:payment, :pending)
      prescription = create(:prescription, :requested, payment: pending_payment)
      expect(prescription.processing?).to be true
    end

    it 'returns false when not requested' do
      prescription = create(:prescription, :ready)
      expect(prescription.processing?).to be false
    end
  end

  describe '#status_badge_color' do
    it 'returns correct colors for each status' do
      expect(build(:prescription, :requested).status_badge_color).to eq('warning')
      expect(build(:prescription, :payment_rejected).status_badge_color).to eq('danger')
      expect(build(:prescription, :ready).status_badge_color).to eq('success')
    end
  end

  describe '#mark_as_ready!' do
    it 'updates status and sets pdf_url and ready_at' do
      prescription = create(:prescription, :requested)
      pdf_url = 'https://example.com/prescription.pdf'

      prescription.mark_as_ready!(pdf_url)

      expect(prescription.reload).to have_attributes(
        status: 'ready',
        pdf_url: pdf_url,
        ready_at: be_within(1.second).of(Time.current)
      )
    end
  end

  describe '.create_request_for_user' do
    it 'creates prescription and broadcasts update' do
      allow(Broadcasting::PrescriptionUpdatesService).to receive(:broadcast_prescription_added)

      prescription = Prescription.create_request_for_user(user, payment)

      expect(prescription).to have_attributes(
        user: user,
        payment: payment,
        status: 'requested',
        requested_at: be_within(1.second).of(Time.current)
      )
      expect(Broadcasting::PrescriptionUpdatesService).to have_received(:broadcast_prescription_added)
        .with(prescription)
    end
  end
end
