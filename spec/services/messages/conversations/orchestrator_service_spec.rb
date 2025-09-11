# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Messages::Conversations::OrchestratorService, type: :service do
  let(:message) { create(:message) }
  let(:orchestrator) { described_class.new(message) }

  describe 'service accessors' do
    it 'provides access to conversation service' do
      expect(orchestrator.conversation).to be_a(Messages::Conversations::DataService)
    end

    it 'provides access to status service' do
      expect(orchestrator.status).to be_a(Messages::Operations::StatusService)
    end

    it 'provides access to routing service' do
      expect(orchestrator.routing).to be_a(Messages::Operations::RoutingService)
    end

    it 'provides access to participant service' do
      expect(orchestrator.participants).to be_a(Messages::Participants::DataService)
    end
  end

  describe 'service lifecycle management' do
    it 'resets services' do
      orchestrator.conversation
      expect(orchestrator.services_loaded).to include(:conversation)

      result = orchestrator.reset_services
      expect(result).to eq(orchestrator)
      expect(orchestrator.services_loaded).to be_empty
    end

    it 'preloads all services' do
      result = orchestrator.preload_services
      expect(result).to eq(orchestrator)
      expect(orchestrator.services_loaded).to contain_exactly(:conversation, :status, :routing, :member)
    end

    it 'checks if service is loaded' do
      expect(orchestrator.service_loaded?(:conversation)).to be false
      orchestrator.conversation
      expect(orchestrator.service_loaded?(:conversation)).to be true
    end
  end

  describe 'service delegation' do
    it 'delegates methods to conversation service' do
      expect(orchestrator).to respond_to(:root)
      expect(orchestrator).to respond_to(:owner)
      expect(orchestrator.root).to eq(message)
    end

    it 'delegates validation methods to status service' do
      expect(orchestrator).to respond_to(:can_transition_to?)
      expect(orchestrator).to respond_to(:available_transitions)
    end
  end
end
