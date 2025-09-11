# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Messages::Participants::DataService, type: :service do
  let(:patient) { create(:user, :patient) }
  let(:doctor) { create(:user, :doctor) }
  let(:admin) { create(:user, :admin) }

  let(:messages) do
    [
      create(:message, outbox: patient.outbox, inbox: doctor.inbox),
      create(:message, outbox: doctor.outbox, inbox: admin.inbox),
      create(:message, outbox: admin.outbox, inbox: patient.inbox)
    ]
  end

  let(:service) { described_class.new(messages) }

  describe '#unique_user_ids' do
    it 'returns unique user IDs from all participants' do
      expect(service.unique_user_ids).to contain_exactly(patient.id, doctor.id, admin.id)
      expect(described_class.new([]).unique_user_ids).to eq([])
    end
  end

  describe '#participants' do
    it 'returns all participant users' do
      expect(service.participants).to contain_exactly(patient, doctor, admin)
    end
  end

  describe 'role-based queries' do
    it 'filters participants by role' do
      expect(service.doctors).to contain_exactly(doctor)
      expect(service.patients).to contain_exactly(patient)
      expect(service.admins).to contain_exactly(admin)
    end

    it 'checks role presence' do
      expect(service.doctor?).to be true
      expect(service.patient?).to be true

      no_doctor_messages = [create(:message, outbox: patient.outbox, inbox: admin.inbox)]
      no_doctor_service = described_class.new(no_doctor_messages)
      expect(no_doctor_service.doctor?).to be false
    end
  end

  describe '#participant_count_by_role' do
    it 'returns count by role' do
      counts = service.participant_count_by_role
      expect(counts[:doctors]).to eq(1)
      expect(counts[:patients]).to eq(1)
      expect(counts[:admins]).to eq(1)
      expect(counts[:total]).to eq(3)
    end
  end

  describe '#find_doctor_in_message' do
    let(:doctor_message) { create(:message, outbox: doctor.outbox, inbox: patient.inbox) }
    let(:patient_message) { create(:message, outbox: patient.outbox, inbox: doctor.inbox) }
    let(:admin_message) { create(:message, outbox: admin.outbox, inbox: patient.inbox) }

    it 'finds doctor in outbox' do
      expect(service.find_doctor_in_message(doctor_message)).to eq(doctor)
    end

    it 'finds doctor in inbox' do
      expect(service.find_doctor_in_message(patient_message)).to eq(doctor)
    end

    it 'returns nil when no doctor' do
      expect(service.find_doctor_in_message(admin_message)).to be_nil
    end
  end

  describe '#find_doctor_in_conversation' do
    it 'finds first doctor in conversation' do
      expect(service.find_doctor_in_conversation).to eq(doctor)
    end

    it 'returns nil when no doctor in conversation' do
      no_doctor_messages = [
        create(:message, outbox: patient.outbox, inbox: admin.inbox),
        create(:message, outbox: admin.outbox, inbox: patient.inbox)
      ]
      no_doctor_service = described_class.new(no_doctor_messages)
      expect(no_doctor_service.find_doctor_in_conversation).to be_nil
    end
  end

  describe '#first_doctor' do
    it 'returns first doctor from participants' do
      expect(service.first_doctor).to eq(doctor)
    end

    it 'returns nil when no doctors' do
      no_doctor_messages = [
        create(:message, outbox: patient.outbox, inbox: admin.inbox),
        create(:message, outbox: admin.outbox, inbox: patient.inbox)
      ]
      no_doctor_service = described_class.new(no_doctor_messages)
      expect(no_doctor_service.first_doctor).to be_nil
    end
  end
end
