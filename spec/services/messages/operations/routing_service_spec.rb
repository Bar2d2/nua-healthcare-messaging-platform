# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Messages::Operations::RoutingService, type: :service do
  let(:patient) { create(:user, :patient) }
  let(:doctor) { create(:user, :doctor) }
  let(:admin) { create(:user, :admin) }

  before do
    patient
    doctor
    admin
  end

  describe '#determine_recipient' do
    context 'when sender is a patient' do
      let(:message) { build(:message, outbox: patient.outbox) }

      context 'with new message' do
        it 'routes to doctor for recent conversation' do
          service = described_class.new(message, patient)
          recipient = service.determine_recipient

          expect(recipient).to eq(doctor)
        end
      end

      context 'with reply to recent conversation' do
        let(:parent_message) { create(:message, created_at: 2.days.ago, outbox: doctor.outbox, inbox: patient.inbox) }
        let(:reply_message) { build(:message, parent_message: parent_message, outbox: patient.outbox) }

        it 'routes to same doctor' do
          service = described_class.new(reply_message, patient)
          recipient = service.determine_recipient

          expect(recipient).to eq(doctor)
        end
      end

      context 'with reply to old conversation' do
        let(:parent_message) { create(:message, created_at: 2.weeks.ago, outbox: doctor.outbox, inbox: patient.inbox) }
        let(:reply_message) { build(:message, parent_message: parent_message, outbox: patient.outbox) }

        it 'routes to admin for old conversation' do
          service = described_class.new(reply_message, patient)
          recipient = service.determine_recipient

          expect(recipient).to eq(admin)
        end
      end

      context 'with no doctors available' do
        before { User.where(is_doctor: true).destroy_all }

        it 'falls back to admin when no doctor available' do
          service = described_class.new(message, patient)
          recipient = service.determine_recipient

          expect(recipient).to eq(admin)
        end
      end

      context 'with no admins available' do
        before { User.where(is_admin: true).destroy_all }

        it 'raises NoAdminAvailableError for old conversations' do
          old_message = create(:message, created_at: 2.weeks.ago, outbox: doctor.outbox, inbox: patient.inbox)
          reply_message = build(:message, parent_message: old_message, outbox: patient.outbox)

          service = described_class.new(reply_message, patient)
          expect { service.determine_recipient }.to raise_error(Messages::Operations::RoutingService::NoAdminAvailableError)
        end
      end
    end

    context 'when sender is a doctor' do
      let(:message) { build(:message, outbox: doctor.outbox) }

      context 'with new message' do
        it 'routes to patient' do
          service = described_class.new(message, doctor)
          recipient = service.determine_recipient

          expect(recipient).to eq(patient)
        end
      end

      context 'with reply to existing conversation' do
        let(:parent_message) { create(:message, outbox: patient.outbox, inbox: doctor.inbox) }
        let(:reply_message) { build(:message, parent_message: parent_message, outbox: doctor.outbox) }

        it 'routes to conversation owner (patient)' do
          service = described_class.new(reply_message, doctor)
          recipient = service.determine_recipient

          expect(recipient).to eq(patient)
        end
      end

      context 'with no patients available' do
        before { User.where(is_patient: true).destroy_all }

        it 'raises NoPatientAvailableError' do
          service = described_class.new(message, doctor)
          expect { service.determine_recipient }.to raise_error(Messages::Operations::RoutingService::NoPatientAvailableError)
        end
      end
    end

    context 'when sender is an admin' do
      let(:message) { build(:message, outbox: admin.outbox) }

      context 'with new message' do
        it 'routes to patient' do
          service = described_class.new(message, admin)
          recipient = service.determine_recipient

          expect(recipient).to eq(patient)
        end
      end

      context 'with reply to existing conversation' do
        let(:parent_message) { create(:message, outbox: patient.outbox, inbox: admin.inbox) }
        let(:reply_message) { build(:message, parent_message: parent_message, outbox: admin.outbox) }

        it 'routes to conversation owner (patient)' do
          service = described_class.new(reply_message, admin)
          recipient = service.determine_recipient

          expect(recipient).to eq(patient)
        end
      end

      context 'with no patients available' do
        before { User.where(is_patient: true).destroy_all }

        it 'raises NoPatientAvailableError' do
          service = described_class.new(message, admin)
          expect { service.determine_recipient }.to raise_error(Messages::Operations::RoutingService::NoPatientAvailableError)
        end
      end
    end

    context 'with unsupported user role' do
      let(:invalid_user) { build(:user, is_patient: false, is_doctor: false, is_admin: false) }
      let(:message) { build(:message, outbox: invalid_user.outbox) }

      it 'raises UnsupportedUserRoleError' do
        allow(invalid_user).to receive(:role).and_return('invalid_role')
        service = described_class.new(message, invalid_user)
        expect { service.determine_recipient }.to raise_error(Messages::Operations::RoutingService::UnsupportedUserRoleError)
      end
    end
  end

  describe 'reply routing logic' do
    context 'when patient replies to doctor message' do
      let(:doctor_message) { create(:message, outbox: doctor.outbox, inbox: patient.inbox) }
      let(:patient_reply) { build(:message, parent_message: doctor_message, outbox: patient.outbox) }

      it 'routes to doctor for recent conversation' do
        service = described_class.new(patient_reply, patient)
        recipient = service.determine_recipient

        expect(recipient).to eq(doctor)
      end
    end

    context 'when doctor replies to patient message' do
      let(:patient_message) { create(:message, outbox: patient.outbox, inbox: doctor.inbox) }
      let(:doctor_reply) { build(:message, parent_message: patient_message, outbox: doctor.outbox) }

      it 'routes to patient' do
        service = described_class.new(doctor_reply, doctor)
        recipient = service.determine_recipient

        expect(recipient).to eq(patient)
      end
    end

    context 'when admin replies to patient message' do
      let(:patient_message) { create(:message, outbox: patient.outbox, inbox: admin.inbox) }
      let(:admin_reply) { build(:message, parent_message: patient_message, outbox: admin.outbox) }

      it 'routes to patient' do
        service = described_class.new(admin_reply, admin)
        recipient = service.determine_recipient

        expect(recipient).to eq(patient)
      end
    end
  end
end
