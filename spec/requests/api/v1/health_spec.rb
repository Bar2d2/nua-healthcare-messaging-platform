# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V1 Health', type: :request do
  describe 'GET /api/v1/health' do
    it 'returns health status' do
      get '/api/v1/health'

      expect(response).to have_http_status(:ok)
      json_response = response.parsed_body

      expect(json_response).to have_key('data')
      expect(json_response).to have_key('meta')
      expect(json_response['data']).to have_key('status')
      expect(json_response['data']['status']).to eq('ok')
      expect(json_response['meta']).to have_key('timestamp')
      expect(json_response['meta']).to have_key('version')
      expect(json_response['data']).to have_key('environment')
      expect(json_response['data']).to have_key('database')
      expect(json_response['data']).to have_key('message_routing')
    end
  end
end
