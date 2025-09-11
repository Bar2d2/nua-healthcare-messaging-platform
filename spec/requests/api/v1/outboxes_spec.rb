# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V1 Outboxes', type: :request do
  let(:patient) { create(:user, :patient) }
  let(:doctor) { create(:user, :doctor) }
  let(:admin) { create(:user, :admin) }

  before do
    doctor
    admin
    allow(User).to receive(:current).and_return(patient)
  end

  describe 'POST /api/v1/outbox/messages' do
    context 'with valid message data' do
      let(:valid_params) do
        {
          message: {
            body: 'Hello, I need medical assistance',
            routing_type: 'direct'
          }
        }
      end

      it 'creates a new message and routes to doctor' do
        post '/api/v1/outbox/messages', params: valid_params

        expect(response).to have_http_status(:created)
        json_response = response.parsed_body

        expect(json_response).to have_key('data')
        expect(json_response['data']).to have_key('id')
        expect(json_response['data']).to have_key('body')
        expect(json_response['data']['body']).to eq('Hello, I need medical assistance')
        expect(json_response['data']).to have_key('recipient')
        expect(json_response['data']['recipient']['role']).to eq('doctor')
      end
    end

    context 'with reply to recent conversation' do
      let(:recent_message) do
        create(:message,
               outbox: patient.outbox,
               inbox: doctor.inbox,
               created_at: 2.days.ago)
      end

      let(:reply_params) do
        {
          message: {
            body: 'Thank you for the response',
            routing_type: 'reply',
            parent_message_id: recent_message.id
          }
        }
      end

      it 'routes reply to the same doctor' do
        post '/api/v1/outbox/messages', params: reply_params

        expect(response).to have_http_status(:created)
        json_response = response.parsed_body

        expect(json_response['data']['recipient']['id']).to eq(doctor.id)
      end
    end

    context 'with reply to old conversation' do
      let(:old_message) do
        create(:message,
               outbox: patient.outbox,
               inbox: doctor.inbox,
               created_at: 2.weeks.ago)
      end

      let(:reply_params) do
        {
          message: {
            body: 'I have a follow-up question',
            routing_type: 'reply',
            parent_message_id: old_message.id
          }
        }
      end

      it 'routes reply to admin' do
        post '/api/v1/outbox/messages', params: reply_params

        expect(response).to have_http_status(:created)
        json_response = response.parsed_body

        expect(json_response['data']['recipient']['role']).to eq('admin')
      end
    end

    context 'with invalid message data' do
      let(:invalid_params) do
        {
          message: {
            body: '',
            routing_type: 'direct'
          }
        }
      end

      it 'returns validation errors' do
        post '/api/v1/outbox/messages', params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = response.parsed_body

        expect(json_response).to have_key('error')
        expect(json_response).to have_key('details')
      end
    end

    context 'with invalid routing type' do
      let(:invalid_params) do
        {
          message: {
            body: 'Test message',
            routing_type: 'invalid'
          }
        }
      end

      it 'returns error' do
        post '/api/v1/outbox/messages', params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with non-existent parent message' do
      let(:invalid_params) do
        {
          message: {
            body: 'Test reply',
            routing_type: 'reply',
            parent_message_id: 'invalid-id'
          }
        }
      end

      it 'returns error' do
        post '/api/v1/outbox/messages', params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with missing routing type' do
      let(:valid_params) do
        {
          message: {
            body: 'Test message without routing type'
          }
        }
      end

      it 'automatically determines routing type' do
        post '/api/v1/outbox/messages', params: valid_params

        expect(response).to have_http_status(:created)
        json_response = response.parsed_body
        expect(json_response['data']).to have_key('id')
      end
    end

    context 'with blank routing type' do
      let(:valid_params) do
        {
          message: {
            body: 'Test message with blank routing type',
            routing_type: ''
          }
        }
      end

      it 'automatically determines routing type' do
        post '/api/v1/outbox/messages', params: valid_params

        expect(response).to have_http_status(:created)
        json_response = response.parsed_body
        expect(json_response['data']).to have_key('id')
      end
    end

    context 'with valid parent message' do
      let(:parent_message) do
        create(:message,
               outbox: patient.outbox,
               inbox: doctor.inbox,
               created_at: 2.days.ago)
      end

      let(:valid_params) do
        {
          message: {
            body: 'Test reply with valid parent',
            routing_type: 'reply',
            parent_message_id: parent_message.id
          }
        }
      end

      it 'successfully creates reply' do
        post '/api/v1/outbox/messages', params: valid_params

        expect(response).to have_http_status(:created)
        json_response = response.parsed_body
        expect(json_response['data']).to have_key('id')
      end
    end

    context 'with message save failure' do
      let(:valid_params) do
        {
          message: {
            body: 'Test message',
            routing_type: 'direct'
          }
        }
      end

      it 'handles save failure gracefully' do
        invalid_params = {
          message: {
            body: '',
            routing_type: 'direct'
          }
        }

        post '/api/v1/outbox/messages', params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = response.parsed_body
        expect(json_response).to have_key('error')
        expect(json_response).to have_key('details')
      end
    end
  end
end
