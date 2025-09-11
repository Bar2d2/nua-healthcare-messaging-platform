# frozen_string_literal: true

module Payments
  # Factory for creating payment provider instances.
  # Centralizes payment provider instantiation and configuration.
  class PaymentProviderFactory
    class << self
      def register(id, provider_class)
        providers[id] = provider_class
      end

      def provider(id = nil)
        (providers[id] || providers.values&.first).new
      end

      private

      def providers
        @providers ||= {
          flaky: Payments::FlakyPaymentProvider
        }
      end
    end
  end
end
