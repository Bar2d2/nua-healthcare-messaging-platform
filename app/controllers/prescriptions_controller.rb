# frozen_string_literal: true

# Controller for prescription management in the medical communication system.
# Handles prescription requests, payment retries, and admin generation workflow.
class PrescriptionsController < ApplicationController
  # GET /prescriptions
  def index
    @pagy, @prescriptions = pagy(
      current_user.prescriptions.recent.includes(:payment),
      items: 10
    )

    render :index
  end

  # POST /prescriptions
  def create
    service = Prescriptions::RequestService.new(current_user)
    result = service.call

    respond_to do |format|
      if result.success?
        format.turbo_stream { render :create_success }
        format.html { redirect_to prescriptions_path, notice: t('prescriptions.notices.created') }
      else
        format.turbo_stream { render :create_error }
        format.html { redirect_to prescriptions_path, alert: result.error_message }
      end
    end
  end

  # POST /prescriptions/:id/retry_payment
  def retry_payment
    @prescription = current_user.prescriptions.find(params[:id])
    service = Prescriptions::RequestService.new(current_user)
    result = service.retry_payment(@prescription)

    respond_to do |format|
      if result.success?
        format.turbo_stream { render :retry_success }
        format.html { redirect_to prescriptions_path, notice: t('prescriptions.notices.payment_retry') }
      else
        format.turbo_stream { render :retry_error }
        format.html { redirect_to prescriptions_path, alert: result.error_message }
      end
    end
  end

  # POST /prescriptions/:id/generate (Admin only)
  def generate
    return head :forbidden unless current_user.is_admin?

    message = Message.find(params[:message_id]) if params[:message_id]
    prescription = Prescription.find(params[:id])

    # Simulate 2-second processing delay to show button state
    sleep 2

    # Enqueue fake prescription generation
    PrescriptionGenerationJob.perform_later(prescription.id, message&.id)

    respond_to do |format|
      format.turbo_stream { render :generate_success, locals: { prescription: prescription } }
      format.html do
        redirect_back(fallback_location: inbox_path, notice: t('prescriptions.notices.generation_started'))
      end
    end
  end
end
