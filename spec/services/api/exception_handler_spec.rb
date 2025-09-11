# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::ExceptionHandler do
  let(:request) { instance_double(ActionController::Base) }
  let(:response_service) { instance_double(Api::ResponseService) }
  let(:handler) { described_class.new(request) }

  before do
    allow(Api::ResponseService).to receive(:new).with(request).and_return(response_service)
  end

  describe '#handle_exception' do
    let(:exception) { StandardError.new('Test error') }
    let(:error_config) { { status: :internal_server_error, message: 'Internal server error' } }

    before do
      allow(Api::ErrorRegistry).to receive(:error_config_for).with(exception).and_return(error_config)
      allow(handler).to receive(:log_exception)
      allow(handler).to receive(:build_response_data).with(exception, error_config).and_return(error_config)
      allow(response_service).to receive(:render_error)
    end

    it 'handles exceptions and renders error response' do
      handler.handle_exception(exception)

      expect(handler).to have_received(:log_exception).with(exception)
      expect(Api::ErrorRegistry).to have_received(:error_config_for).with(exception)
      expect(response_service).to have_received(:render_error).with(
        error_config[:message], status: error_config[:status], details: nil
      )
    end
  end

  describe '#log_exception' do
    let(:logger) { instance_double(ActiveSupport::Logger) }

    before do
      allow(Rails).to receive(:logger).and_return(logger)
      allow(logger).to receive(:info)
      allow(logger).to receive(:warn)
      allow(logger).to receive(:error)
    end

    it 'logs different exception types appropriately' do
      handler.send(:log_exception, ActiveRecord::RecordNotFound.new('Not found'))
      expect(logger).to have_received(:info).with(/API: Record not found/)

      handler.send(:log_exception, ActionController::ParameterMissing.new('user'))
      expect(logger).to have_received(:warn).with(/API: Parameter error/)

      handler.send(:log_exception, StandardError.new('Unknown'))
      expect(logger).to have_received(:error).with(/API: Unhandled exception/)
    end
  end

  describe '#build_response_data' do
    it 'builds response data with details when available' do
      user = build(:user, first_name: nil)
      user.valid?
      exception = ActiveRecord::RecordInvalid.new(user)
      config = { message: 'Validation failed', status: :unprocessable_entity, include_details: true }

      result = handler.send(:build_response_data, exception, config)

      expect(result[:message]).to eq('Validation failed')
      expect(result[:status]).to eq(:unprocessable_entity)
      expect(result[:details]).to eq(user.errors.full_messages)
    end
  end
end
