# frozen_string_literal: true

module Payments
  # Simulates a flaky payment provider for testing purposes.
  # - Fails every 5th NEW payment request
  # - Always succeeds on RETRY requests (retry_count > 0)
  class FlakyPaymentProvider
    # Raised when payment processing fails
    class PaymentError < StandardError; end

    # Simple in-memory counter for new payments
    @@counter = 0

    def debit(_amount, payment_id: nil)
      sleep(rand(1..2)) unless Rails.env.test?

      payment = Payment.find(payment_id) if payment_id
      is_retry = payment&.retry_count&.> 0

      # ALWAYS succeed on retry requests
      if is_retry
        Rails.logger.info "💳 Payment SUCCESS for retry (retry_count: #{payment.retry_count})"
        return true
      end

      # For NEW payments: fail every 5th attempt
      @@counter += 1
      should_fail = (@@counter % 5).zero?

      if should_fail
        Rails.logger.warn "💳 Payment FAILED for new payment ##{@@counter} (every 5th fails)"
        raise PaymentError, 'Payment provider temporarily unavailable'
      else
        Rails.logger.info "💳 Payment SUCCESS for new payment ##{@@counter}"
        true
      end
    end

    # Reset counter (useful for demos)
    def self.reset!
      @@counter = 0
      Rails.logger.info 'FlakyPaymentProvider: Counter reset'
    end
  end
end
