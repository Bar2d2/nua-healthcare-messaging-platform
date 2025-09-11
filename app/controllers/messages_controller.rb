# frozen_string_literal: true

# Main controller for message management in the medical communication system.
# Handles the web interface for viewing and sending messages between users.
class MessagesController < ApplicationController
  def inbox
    # High-performance paginated inbox with optimized queries
    @pagy, @messages = pagy(
      Messages::Queries::LoaderService.inbox_messages_for_user(current_user),
      items: 10 # Optimized page size for performance
    )

    # Don't mark messages as read when viewing the list - only when viewing individual messages
    render :inbox
  end

  def outbox
    # High-performance paginated outbox with optimized queries
    @pagy, @messages = pagy(
      Messages::Queries::LoaderService.outbox_messages_for_user(current_user),
      items: 10 # Optimized page size for performance
    )
    render :outbox
  end

  def index
    redirect_to inbox_path
  end

  def show
    @message = Messages::Queries::LoaderService.find_message_safely(params[:id])

    return head :not_found unless @message

    # Mark all unread messages in this conversation that belong to current user's inbox as read
    Messages::Conversations::ActionsService.mark_conversation_as_read(@message, current_user)
  end

  def new
    @message = Messages::Conversations::ActionsService.prepare_new_message(params[:parent_message_id], current_user)

    # Determine recipient for new messages (not replies)
    @recipient = Messages::Conversations::ActionsService.determine_recipient_for_message(@message, current_user)
  end

  def create
    message_params = MessageParams.new(request_message_params)

    unless message_params.valid?
      @message = Message.new(message_params.to_message_attributes)
      @message.errors.merge!(message_params.errors)
      return Messages::Presentation::ResponseService.handle_error_response(self, :new)
    end

    Messages::Presentation::ResponseService.handle_message_creation(self, message_params, current_user)
  end

  def update
    @message = Messages::Queries::LoaderService.find_message_safely(params[:id])
    return head :not_found unless @message

    Messages::Presentation::ResponseService.handle_message_update(self, @message, request_message_params)
  end

  def mark_all_read
    current_user.inbox&.mark_all_as_read!
    Messages::Presentation::ResponseService.handle_mark_all_read_response(self)
  end

  private

  def request_message_params
    params.require(:message).permit(:body, :routing_type, :parent_message_id, :status)
  end
end
