# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::ErrorRegistry do
  describe '.error_config_for' do
    it 'returns correct config for registered exceptions' do
      expect(described_class.error_config_for(Messages::Operations::RoutingService::NoDoctorAvailableError.new))
        .to include(status: :service_unavailable, message: 'No doctors are currently available')

      expect(described_class.error_config_for(ActiveRecord::RecordNotFound.new))
        .to include(status: :not_found, message: 'Resource not found')
    end

    it 'returns default config for unknown exceptions' do
      config = described_class.error_config_for(StandardError.new)
      expect(config).to include(status: :internal_server_error, message: 'Internal server error')
    end
  end

  describe '.default_error_config' do
    it 'returns default configuration' do
      config = described_class.default_error_config
      expect(config).to include(status: :internal_server_error, message: 'Internal server error')
    end
  end

  describe '.registered_exceptions' do
    it 'returns list of exception classes' do
      exceptions = described_class.registered_exceptions
      expect(exceptions).to include(Messages::Operations::RoutingService::NoDoctorAvailableError)
      expect(exceptions).to include(ActiveRecord::RecordNotFound)
    end
  end
end
