# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_one(:inbox).dependent(:destroy) }
    it { should have_one(:outbox).dependent(:destroy) }
    it { should have_many(:payments).dependent(:destroy) }
    it { should have_many(:inbox_messages).through(:inbox).source(:messages) }
    it { should have_many(:outbox_messages).through(:outbox).source(:messages) }
  end

  describe 'scopes' do
    let!(:patient_user) { create(:user, :patient) }
    let!(:admin_user) { create(:user, :admin) }
    let!(:doctor_user) { create(:user, :doctor) }

    describe '.patient' do
      it 'returns only patient users' do
        expect(User.patient).to include(patient_user)
        expect(User.patient).not_to include(admin_user, doctor_user)
      end
    end

    describe '.admin' do
      it 'returns only admin users' do
        expect(User.admin).to include(admin_user)
        expect(User.admin).not_to include(patient_user, doctor_user)
      end
    end

    describe '.doctor' do
      it 'returns only doctor users' do
        expect(User.doctor).to include(doctor_user)
        expect(User.doctor).not_to include(patient_user, admin_user)
      end
    end
  end

  describe 'class methods' do
    describe '.current' do
      it 'returns the first patient user' do
        create(:user, :patient)
        expect(User.current).to be_a(User)
        expect(User.current.is_patient).to be true
      end
    end

    describe '.default_admin' do
      it 'returns the first admin user' do
        create(:user, :admin)
        expect(User.default_admin).to be_a(User)
        expect(User.default_admin.is_admin).to be true
      end
    end

    describe '.default_doctor' do
      it 'returns the first doctor user' do
        create(:user, :doctor)
        expect(User.default_doctor).to be_a(User)
        expect(User.default_doctor.is_doctor).to be true
      end
    end
  end

  describe 'instance methods' do
    let(:user) { create(:user, first_name: 'John', last_name: 'Doe') }

    describe '#full_name' do
      it 'returns the full name of the user' do
        expect(user.full_name).to eq('John Doe')
      end

      it 'handles empty names' do
        user.first_name = ''
        user.last_name = ''
        expect(user.full_name).to eq(' ')
      end

      it 'handles nil names' do
        user.first_name = nil
        user.last_name = nil
        expect(user.full_name).to eq(' ')
      end

      it 'handles mixed nil and empty names' do
        user.first_name = nil
        user.last_name = ''
        expect(user.full_name).to eq(' ')
      end

      it 'handles single name' do
        user.first_name = 'John'
        user.last_name = nil
        expect(user.full_name).to eq('John ')
      end
    end

    describe '#role' do
      it 'returns admin for admin users' do
        admin = create(:user, :admin)
        expect(admin.role).to eq('admin')
      end

      it 'returns doctor for doctor users' do
        doctor = create(:user, :doctor)
        expect(doctor.role).to eq('doctor')
      end

      it 'returns patient for patient users' do
        patient = create(:user, :patient)
        expect(patient.role).to eq('patient')
      end

      it 'returns patient as default role' do
        user = build(:user, is_admin: false, is_doctor: false, is_patient: false)
        expect(user.role).to eq('patient')
      end
    end
  end

  describe 'factory' do
    it 'creates a valid user' do
      user = build(:user)
      expect(user).to be_valid
    end

    it 'creates a valid admin user' do
      user = build(:user, :admin)
      expect(user).to be_valid
      expect(user.is_admin).to be true
      expect(user.is_patient).to be false
      expect(user.is_doctor).to be false
    end

    it 'creates a valid doctor user' do
      user = build(:user, :doctor)
      expect(user).to be_valid
      expect(user.is_doctor).to be true
      expect(user.is_patient).to be false
      expect(user.is_admin).to be false
    end

    it 'creates a valid patient user' do
      user = build(:user, :patient)
      expect(user).to be_valid
      expect(user.is_patient).to be true
      expect(user.is_admin).to be false
      expect(user.is_doctor).to be false
    end

    it 'automatically creates inbox and outbox for new users' do
      user = create(:user)
      expect(user.inbox).to be_present
      expect(user.outbox).to be_present
    end
  end

  describe 'through associations' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let!(:inbox_message) { create(:message, inbox: user.inbox, outbox: other_user.outbox) }
    let!(:outbox_message) { create(:message, inbox: other_user.inbox, outbox: user.outbox) }

    it 'can access inbox messages through inbox association' do
      expect(user.inbox_messages).to include(inbox_message)
      expect(user.inbox_messages).not_to include(outbox_message)
    end

    it 'can access outbox messages through outbox association' do
      expect(user.outbox_messages).to include(outbox_message)
      expect(user.outbox_messages).not_to include(inbox_message)
    end
  end
end
