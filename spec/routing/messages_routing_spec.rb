# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Messages routing', type: :routing do
  describe 'GET /messages/:id' do
    it 'routes to messages#show' do
      expect(get: '/messages/1').to route_to('messages#show', id: '1')
    end
  end

  describe 'GET /messages/new' do
    it 'routes to messages#new' do
      expect(get: '/messages/new').to route_to('messages#new')
    end
  end
end
