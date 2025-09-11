# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Messages::ViewDecorator, type: :decorator do
  let(:patient) { create(:user, :patient) }
  let(:doctor) { create(:user, :doctor) }

  let(:root_message) { create(:message, outbox: patient.outbox, inbox: doctor.inbox) }
  let(:reply_message) do
    create(:message, :reply, outbox: doctor.outbox, inbox: patient.inbox, parent_message: root_message)
  end

  let(:decorated_message) { Messages::BaseDecorator.new(reply_message) }

  describe '#conversation_history_html' do
    before { root_message }

    it 'generates HTML for conversation history' do
      html = decorated_message.conversation_history_html
      expect(html).to include('conversation-history')
      expect(html).to include('Conversation History')
    end

    it 'includes all conversation messages' do
      html = decorated_message.conversation_history_html
      expect(html).to include(root_message.body)
      expect(html).to include(reply_message.body)
    end
  end

  describe '#conversation_message_html' do
    it 'generates HTML for individual message' do
      html = decorated_message.conversation_message_html
      expect(html).to include('message')
      expect(html).to include('doctor-message') # doctor is the sender
      expect(html).to include(reply_message.body)
    end

    it 'applies correct CSS class based on sender role' do
      patient_message = Messages::BaseDecorator.new(root_message)
      html = patient_message.conversation_message_html
      expect(html).to include('patient-message')
    end
  end

  describe '#message_header_html' do
    it 'generates HTML for message header' do
      html = decorated_message.message_header_html
      expect(html).to include('message-header')
      expect(html).to include(doctor.full_name)
      expect(html).to include('ago')
    end
  end

  describe '#message_body_html' do
    it 'generates HTML for message body' do
      html = decorated_message.message_body_html
      expect(html).to include('message-body')
      expect(html).to include(reply_message.body)
    end
  end

  describe '#sender_role_icon' do
    it 'returns correct icon for doctor sender' do
      expect(decorated_message.sender_role_icon).to eq('🩺')
    end

    it 'returns correct icon for patient sender' do
      patient_message = Messages::BaseDecorator.new(root_message)
      expect(patient_message.sender_role_icon).to eq('👩‍⚕️')
    end
  end

  describe '#recipient_role_icon' do
    it 'returns correct icon for patient recipient' do
      expect(decorated_message.recipient_role_icon).to eq('👩‍⚕️')
    end

    it 'returns correct icon for doctor recipient' do
      patient_message = Messages::BaseDecorator.new(root_message)
      expect(patient_message.recipient_role_icon).to eq('🩺')
    end
  end
end
