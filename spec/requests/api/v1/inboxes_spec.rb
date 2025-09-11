# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V1 Inboxes', type: :request do
  let(:patient) { create(:user, :patient) }
  let(:doctor) { create(:user, :doctor) }
  let(:admin) { create(:user, :admin) }

  before do
    doctor
    admin
    allow(Api::AuthenticationService).to receive(:current_user).and_return(patient)
  end

  describe 'GET /api/v1/inbox/messages' do
    context 'when user has messages' do
      before do
        create(:message, inbox: patient.inbox, outbox: doctor.outbox)
        create(:message, inbox: patient.inbox, outbox: admin.outbox)
      end

      it 'returns list of messages' do
        get '/api/v1/inbox/messages'

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body

        expect(json_response).to have_key('data')
        expect(json_response['data']).to be_an(Array)
        expect(json_response['data'].length).to eq(2)

        message = json_response['data'].first
        expect(message).to have_key('id')
        expect(message).to have_key('body')
        expect(message).to have_key('status')
        expect(message).to have_key('created_at')
      end
    end

    context 'when user has no messages' do
      it 'returns empty array' do
        get '/api/v1/inbox/messages'

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body

        expect(json_response).to have_key('data')
        expect(json_response['data']).to be_empty
      end
    end
  end

  describe 'GET /api/v1/inbox/unread' do
    context 'when user has unread messages' do
      before do
        create(:message, inbox: patient.inbox, outbox: doctor.outbox, read: false)
        create(:message, inbox: patient.inbox, outbox: admin.outbox, read: false)
      end

      it 'returns unread count' do
        get '/api/v1/inbox/unread'

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body

        expect(json_response).to have_key('data')
        expect(json_response['data']).to have_key('unread_count')
        expect(json_response['data']['unread_count']).to eq(2)
      end
    end

    context 'when user has no unread messages' do
      it 'returns zero count' do
        get '/api/v1/inbox/unread'

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body

        expect(json_response).to have_key('data')
        expect(json_response['data']).to have_key('unread_count')
        expect(json_response['data']['unread_count']).to eq(0)
      end
    end
  end

  describe 'GET /api/v1/inbox/conversations' do
    context 'when user has conversations' do
      let(:conversation_root) { create(:message, inbox: patient.inbox, outbox: doctor.outbox) }

      before do
        create(:message, inbox: patient.inbox, outbox: doctor.outbox, parent_message: conversation_root)
        create(:message, inbox: patient.inbox, outbox: admin.outbox)
      end

      it 'returns conversation list' do
        get '/api/v1/inbox/conversations'

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body

        expect(json_response).to have_key('data')
        expect(json_response['data']).to be_an(Array)
        expect(json_response['data'].length).to eq(2)
      end
    end
  end
end
