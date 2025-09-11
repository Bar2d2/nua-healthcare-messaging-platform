# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V1 Messages', type: :request do
  let(:patient) { create(:user, :patient) }
  let(:doctor) { create(:user, :doctor) }

  before do
    doctor
    allow(User).to receive(:current).and_return(patient)
  end

  describe 'PATCH /api/v1/messages/:id' do
    let(:message) { create(:message, inbox: patient.inbox, outbox: doctor.outbox, read: false) }

    context 'with valid status update' do
      let(:valid_params) do
        {
          message: {
            status: 'read'
          }
        }
      end

      it 'updates message status' do
        patch "/api/v1/messages/#{message.id}", params: valid_params

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body

        expect(json_response).to have_key('data')
        expect(json_response['data']['status']).to eq('read')
        expect(json_response['data']['id']).to eq(message.id)
      end
    end

    context 'with invalid message id' do
      let(:valid_params) do
        {
          message: {
            status: 'read'
          }
        }
      end

      it 'returns not found error' do
        patch '/api/v1/messages/invalid-id', params: valid_params

        expect(response).to have_http_status(:not_found)
        json_response = response.parsed_body

        expect(json_response).to have_key('error')
        expect(json_response['error']).to eq('Message not found')
      end
    end

    context 'with message not in user inbox' do
      let(:other_message) { create(:message, inbox: doctor.inbox, outbox: patient.outbox) }
      let(:valid_params) do
        {
          message: {
            status: 'read'
          }
        }
      end

      it 'returns not found error' do
        patch "/api/v1/messages/#{other_message.id}", params: valid_params

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with invalid status' do
      let(:invalid_params) do
        {
          message: {
            status: 'invalid_status'
          }
        }
      end

      it 'returns validation error' do
        patch "/api/v1/messages/#{message.id}", params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = response.parsed_body

        expect(json_response).to have_key('error')
      end
    end

    context 'with blank status' do
      let(:valid_params) do
        {
          message: {
            status: ''
          }
        }
      end

      it 'allows blank status' do
        patch "/api/v1/messages/#{message.id}", params: valid_params

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body
        expect(json_response).to have_key('data')
      end
    end

    context 'with nil status' do
      let(:valid_params) do
        {
          message: {
            status: nil
          }
        }
      end

      it 'allows nil status' do
        patch "/api/v1/messages/#{message.id}", params: valid_params

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body
        expect(json_response).to have_key('data')
      end
    end

    context 'with message update failure' do
      let(:valid_params) do
        {
          message: {
            status: 'read'
          }
        }
      end

      it 'handles update failure gracefully' do
        invalid_params = { message: { status: 'invalid_status' } }
        patch "/api/v1/messages/#{message.id}", params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = response.parsed_body
        expect(json_response).to have_key('error')
      end
    end
  end
end
