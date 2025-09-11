# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Payments::PaymentProviderFactory do
  describe '.provider' do
    it 'creates a flaky payment provider by default' do
      provider = described_class.provider
      expect(provider).to be_a(Payments::FlakyPaymentProvider)
    end

    it 'creates a flaky payment provider when specified' do
      provider = described_class.provider(:flaky)
      expect(provider).to be_a(Payments::FlakyPaymentProvider)
    end

    it 'creates a new instance each time' do
      provider1 = described_class.provider(:flaky)
      provider2 = described_class.provider(:flaky)
      expect(provider1).not_to eq(provider2)
    end
  end

  describe '.register' do
    it 'can register a new provider' do
      dummy_provider_class = Class.new

      # Register the new provider
      described_class.register(:dummy, dummy_provider_class)

      # Verify we can create the provider (this exercises the register functionality)
      provider = described_class.provider(:dummy)
      expect(provider).to be_a(dummy_provider_class)
    end
  end
end
