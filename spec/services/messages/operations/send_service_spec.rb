# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Messages::Operations::SendService, type: :service do
  let(:patient) { create(:user, :patient) }
  let(:doctor) { create(:user, :doctor) }
  let(:admin) { create(:user, :admin) }

  before do
    patient
    doctor
    admin
  end

  describe '#call' do
    context 'when sender is a patient' do
      let(:message_params) { MessageParams.new(body: 'Test message from patient', routing_type: 'direct') }

      context 'with valid parameters' do
        it 'creates and delivers a message to doctor successfully' do
          service = described_class.new(message_params, patient)
          result = service.call

          expect(result.success?).to be true
          expect(result.data).to be_persisted
          expect(result.data.body).to eq('Test message from patient')
          expect(result.data.routing_type).to eq('direct')
          expect(result.data.outbox).to eq(patient.outbox)
          expect(result.data.inbox.user).to eq(doctor)
        end
      end

      context 'with reply to recent conversation' do
        let(:parent_message) { create(:message, outbox: doctor.outbox, inbox: patient.inbox, created_at: 2.days.ago) }
        let(:reply_params) do
          MessageParams.new(body: 'Reply from patient', routing_type: 'reply', parent_message_id: parent_message.id)
        end

        it 'routes reply to the same doctor' do
          service = described_class.new(reply_params, patient)
          result = service.call

          expect(result.success?).to be true
          expect(result.data.inbox.user).to eq(doctor)
        end
      end

      context 'with reply to old conversation' do
        let(:parent_message) { create(:message, outbox: patient.outbox, inbox: doctor.inbox, created_at: 2.weeks.ago) }
        let(:reply_params) do
          MessageParams.new(body: 'Reply to old conversation', routing_type: 'reply',
                            parent_message_id: parent_message.id)
        end

        it 'routes reply to admin for old conversation' do
          expect(parent_message.conversation_owner).to eq(patient)

          service = described_class.new(reply_params, patient)
          result = service.call

          expect(result.success?).to be true
          expect(result.data.inbox.user).to eq(admin)
        end
      end
    end

    context 'when sender is a doctor' do
      let(:message_params) { MessageParams.new(body: 'Test message from doctor', routing_type: 'direct') }

      context 'with valid parameters' do
        it 'creates and delivers a message to patient successfully' do
          service = described_class.new(message_params, doctor)
          result = service.call

          expect(result.success?).to be true
          expect(result.data).to be_persisted
          expect(result.data.body).to eq('Test message from doctor')
          expect(result.data.routing_type).to eq('direct')
          expect(result.data.outbox).to eq(doctor.outbox)
          expect(result.data.inbox.user).to eq(patient)
        end
      end

      context 'with reply to existing conversation' do
        let(:parent_message) { create(:message, outbox: patient.outbox, inbox: doctor.inbox) }
        let(:reply_params) do
          MessageParams.new(body: 'Reply from doctor', routing_type: 'reply', parent_message_id: parent_message.id)
        end

        it 'routes reply to the patient' do
          service = described_class.new(reply_params, doctor)
          result = service.call

          expect(result.success?).to be true
          expect(result.data.inbox.user).to eq(patient)
        end
      end
    end

    context 'when sender is an admin' do
      let(:message_params) { MessageParams.new(body: 'Test message from admin', routing_type: 'direct') }

      context 'with valid parameters' do
        it 'creates and delivers a message to patient successfully' do
          service = described_class.new(message_params, admin)
          result = service.call

          expect(result.success?).to be true
          expect(result.data).to be_persisted
          expect(result.data.body).to eq('Test message from admin')
          expect(result.data.routing_type).to eq('direct')
          expect(result.data.outbox).to eq(admin.outbox)
          expect(result.data.inbox.user).to eq(patient)
        end
      end

      context 'with reply to existing conversation' do
        let(:parent_message) { create(:message, outbox: patient.outbox, inbox: admin.inbox) }
        let(:reply_params) do
          MessageParams.new(body: 'Reply from admin', routing_type: 'reply', parent_message_id: parent_message.id)
        end

        it 'routes reply to the patient' do
          service = described_class.new(reply_params, admin)
          result = service.call

          expect(result.success?).to be true
          expect(result.data.inbox.user).to eq(patient)
        end
      end
    end

    context 'with no recipients available' do
      let(:message_params) { MessageParams.new(body: 'Test message', routing_type: 'direct') }

      context 'when no doctors available for patient' do
        before { User.where(is_doctor: true).destroy_all }

        it 'falls back to admin successfully' do
          service = described_class.new(message_params, patient)
          result = service.call

          expect(result.success?).to be true
          expect(result.data.inbox.user).to eq(admin)
        end
      end

      context 'when no patients available for doctor' do
        before { User.where(is_patient: true).destroy_all }

        it 'returns failure result' do
          service = described_class.new(message_params, doctor)
          result = service.call

          expect(result.success?).to be false
          expect(result.error_message).to eq('No recipients available')
        end
      end

      context 'when no patients available for admin' do
        before { User.where(is_patient: true).destroy_all }

        it 'returns failure result' do
          service = described_class.new(message_params, admin)
          result = service.call

          expect(result.success?).to be false
          expect(result.error_message).to eq('No recipients available')
        end
      end
    end

    context 'with invalid message parameters' do
      let(:invalid_params) { MessageParams.new(body: '', routing_type: 'direct') }

      it 'handles validation errors gracefully' do
        service = described_class.new(invalid_params, patient)
        result = service.call

        expect(result.success?).to be false
        expect(result.error_details).to include("Body can't be blank")
      end
    end
  end
end
