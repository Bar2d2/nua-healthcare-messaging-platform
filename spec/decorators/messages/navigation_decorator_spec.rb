# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Messages::NavigationDecorator, type: :decorator do
  let(:patient) { create(:user, :patient) }
  let(:doctor) { create(:user, :doctor) }

  let(:received_message) { create(:message, inbox: patient.inbox, outbox: doctor.outbox) }
  let(:decorated_message) { Messages::BaseDecorator.new(received_message) }

  describe '#inbox_active?' do
    it 'returns true when on inbox path' do
      request = double('request', path: '/inbox')
      expect(decorated_message.inbox_active?(patient, request)).to be true
    end

    it 'returns true when viewing received message' do
      request = double('request', path: '/messages/123')
      expect(decorated_message.inbox_active?(patient, request)).to be true
    end

    it 'returns false when viewing sent message' do
      request = double('request', path: '/messages/123')
      expect(decorated_message.inbox_active?(doctor, request)).to be false
    end
  end

  describe '#outbox_active?' do
    it 'returns true when on outbox path' do
      request = double('request', path: '/outbox')
      expect(decorated_message.outbox_active?(doctor, request)).to be true
    end

    it 'returns true when viewing sent message' do
      request = double('request', path: '/messages/123')
      expect(decorated_message.outbox_active?(doctor, request)).to be true
    end

    it 'returns false when viewing received message' do
      request = double('request', path: '/messages/123')
      expect(decorated_message.outbox_active?(patient, request)).to be false
    end
  end

  describe '#navigation_context' do
    it 'returns navigation context for user' do
      request = double('request', path: '/messages/123')
      context = decorated_message.navigation_context(patient, request)

      expect(context[:inbox]).to be true
      expect(context[:outbox]).to be false
    end
  end
end
