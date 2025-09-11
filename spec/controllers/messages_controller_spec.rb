# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MessagesController, type: :request do
  describe 'GET /messages/:id' do
    let(:user) { create(:user) }
    let(:message) { create(:message, inbox: user.inbox, outbox: user.outbox) }

    before do
      get message_path(message)
    end

    it 'returns http success' do
      expect(response).to have_http_status(:success)
    end

    it 'displays the message content' do
      expect(response.body).to include(message.body)
    end

    context 'when message does not exist' do
      it 'returns 404 status' do
        get message_path(id: 'non-existent-id')
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET /messages/new' do
    let(:user) { create(:user, :patient) }

    before do
      allow(User).to receive(:current).and_return(user)
      get new_message_path
    end

    it 'returns http success' do
      expect(response).to have_http_status(:success)
    end

    it 'displays the new message form' do
      expect(response.body).to include('New Message')
    end
  end

  describe 'GET /' do
    let(:user) { create(:user, :patient) }

    before do
      allow(User).to receive(:current).and_return(user)
      get root_path
    end

    it 'redirects to inbox' do
      expect(response).to redirect_to(inbox_path)
    end
  end

  describe 'GET /inbox' do
    let(:user) { create(:user, :patient) }
    let!(:root_message) { create(:message, inbox: user.inbox, outbox: user.outbox, created_at: 1.day.ago) }
    let!(:reply_message) do
      create(:message, inbox: user.inbox, outbox: user.outbox, parent_message: root_message, created_at: 2.days.ago)
    end

    before do
      allow(User).to receive(:current).and_return(user)
      get inbox_path
    end

    it 'returns http success' do
      expect(response).to have_http_status(:success)
    end

    it 'displays received messages' do
      expect(response.body).to include(root_message.body)
      expect(response.body).to include('Inbox')
    end

    it 'shows all messages including replies' do
      expect(response.body).to include(root_message.body)
      expect(response.body).to include(reply_message.body)
    end
  end

  describe 'GET /outbox' do
    let(:user) { create(:user, :patient) }
    let!(:sent_message) { create(:message, inbox: user.inbox, outbox: user.outbox, created_at: 1.day.ago) }
    let!(:reply_message) do
      create(:message, inbox: user.inbox, outbox: user.outbox, parent_message: sent_message, created_at: 2.days.ago)
    end

    before do
      allow(User).to receive(:current).and_return(user)
      get outbox_path
    end

    it 'returns http success' do
      expect(response).to have_http_status(:success)
    end

    it 'displays sent messages' do
      expect(response.body).to include(sent_message.body)
      expect(response.body).to include('Outbox')
    end

    it 'shows all sent messages including replies' do
      expect(response.body).to include(sent_message.body)
      expect(response.body).to include(reply_message.body)
    end
  end

  describe 'POST /messages' do
    let(:user) { create(:user, :patient) }
    let!(:doctor) { create(:user, :doctor) }
    let!(:admin) { create(:user, :admin) }

    before do
      allow(User).to receive(:current).and_return(user)
    end

    context 'with valid parameters' do
      let(:valid_params) do
        {
          message: {
            body: 'Test message body'
          }
        }
      end

      it 'creates message synchronously in test environment' do
        expect do
          post messages_path, params: valid_params
        end.to change(Message, :count).by(1)

        expect(response).to redirect_to(outbox_path)
        expect(flash[:notice]).to eq(I18n.t('messages.notice.created'))
      end

      it 'redirects to outbox' do
        post messages_path, params: valid_params
        expect(response).to redirect_to(outbox_path)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          message: {
            body: ''
          }
        }
      end

      it 'does not create a message' do
        expect do
          post messages_path, params: invalid_params
        end.not_to change(Message, :count)
      end

      it 'renders new template' do
        post messages_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH /messages/:id' do
    let(:user) { create(:user, :patient) }
    let!(:message) { create(:message, inbox: user.inbox, outbox: user.outbox) }

    before do
      allow(User).to receive(:current).and_return(user)
    end

    context 'with valid parameters' do
      let(:valid_params) do
        {
          message: {
            status: 'read'
          }
        }
      end

      it 'updates the message' do
        patch message_path(message), params: valid_params, headers: { 'Accept' => 'text/html' }
        expect(response).to redirect_to(message_path(message))
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          message: {
            status: 'invalid_status'
          }
        }
      end

      it 'renders show template' do
        patch message_path(message), params: invalid_params, headers: { 'Accept' => 'text/html' }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'error handling' do
    context 'when accessing a non-existent message' do
      it 'returns 404 status' do
        get message_path(id: 'non-existent-id')
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
