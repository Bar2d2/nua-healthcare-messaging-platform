# frozen_string_literal: true

# Handles and validates message update parameters.
# Used specifically for updating existing messages (status, etc.).
class MessageUpdateParams
  include ActiveModel::Model
  include ActiveModel::Validations

  # == Attributes ==
  attr_accessor :body, :routing_type, :parent_message_id, :status

  # == Validations ==
  validates :routing_type, inclusion: { in: Message.routing_types.keys }, allow_blank: true
  validate :parent_message_exists, if: :parent_message_id?

  # == Public Interface ==

  # Initialize with message update parameters
  def initialize(request_params = {})
    @body = request_params[:body]
    @routing_type = request_params[:routing_type]
    @parent_message_id = request_params[:parent_message_id]
    @status = request_params[:status]
  end

  # Convert to message attributes hash
  def to_message_attributes
    {
      body: body,
      routing_type: routing_type,
      parent_message_id: parent_message_id,
      status: status
    }.compact
  end

  private

  # Validate that parent message exists in system
  def parent_message_exists
    return if parent_message_id.blank?

    parent_message = Message.find_by(id: parent_message_id)
    return if parent_message

    errors.add(:parent_message_id, 'Parent message not found')
  end

  # Check if parent message ID is present for validation
  def parent_message_id?
    parent_message_id.present?
  end
end
