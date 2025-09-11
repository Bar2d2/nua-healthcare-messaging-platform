# frozen_string_literal: true

module Prescriptions
  # Handles prescription request workflow with payment processing.
  # Orchestrates payment creation, processing, and admin notification.
  class RequestService
    attr_reader :user, :payment, :prescription

    def initialize(user)
      @user = user
      @payment = nil
      @prescription = nil
    end

    # == Public Interface ==

    # Main service method - orchestrates prescription request workflow
    def call
      create_payment
      create_prescription_record
      enqueue_payment_processing

      Api::ResponseResult.success(
        {
          prescription: prescription,
          payment: payment,
          message: I18n.t('prescriptions.notices.created')
        }
      )
    rescue StandardError => e
      Rails.logger.error "Prescription request failed for user #{user.id}: #{e.message}"

      Api::ResponseResult.failure(
        'Failed to submit prescription request',
        details: [e.message]
      )
    end

    # Retry failed payment (manual retry always allowed)
    def retry_payment(existing_prescription)
      @prescription = existing_prescription
      @payment = prescription.payment

      return Api::ResponseResult.failure('Payment not found') unless payment
      return Api::ResponseResult.failure('Payment already completed') if payment.completed?

      enqueue_payment_processing

      Api::ResponseResult.success(
        {
          prescription: prescription,
          payment: payment,
          message: I18n.t('prescriptions.notices.payment_retry')
        }
      )
    rescue StandardError => e
      Rails.logger.error "Payment retry failed for prescription #{prescription.id}: #{e.message}"

      Api::ResponseResult.failure(
        'Failed to retry payment',
        details: [e.message]
      )
    end

    private

    # Create payment record for prescription request
    def create_payment
      @payment = Payment.create_for_prescription(user, 10.0)
    end

    # Create prescription record linked to payment
    def create_prescription_record
      @prescription = Prescription.create_request_for_user(user, payment)
    end

    # Enqueue background job for payment processing
    def enqueue_payment_processing
      PrescriptionPaymentJob.perform_later(payment.id)
    end
  end
end
