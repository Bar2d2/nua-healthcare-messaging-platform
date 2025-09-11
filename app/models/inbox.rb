# frozen_string_literal: true

# Represents a user's inbox for receiving messages.
# Part of the inbox/outbox pattern for message routing in the medical communication system.
class Inbox < ApplicationRecord
  belongs_to :user
  has_many :messages, dependent: :nullify

  # == Unread Count Management ==

  # Get cached unread count (with fallback to database)
  def cached_unread_count
    Caching::UnreadCountService.get_unread_count(self)
  end

  # Increment unread count (when new message arrives)
  def increment_unread_count!
    Inboxes::Operations::ActionsService.increment!(self)
  end

  # Decrement unread count (when message is read)
  def decrement_unread_count!
    Inboxes::Operations::ActionsService.decrement!(self)
  end

  # Reset unread count to zero
  def reset_unread_count!
    Inboxes::Operations::ActionsService.reset!(self)
  end

  # Set unread count to specific value
  def set_unread_count!(count)
    Inboxes::Operations::ActionsService.set!(self, count)
  end

  # Recalculate unread count from actual messages
  def recalculate_unread_count!
    Inboxes::Operations::ActionsService.recalculate!(self)
  end

  # Check if inbox has unread messages (using cached count)
  def unread_messages?
    cached_unread_count.positive?
  end

  # Get unread messages
  def unread_messages
    messages.unread.order(created_at: :desc)
  end

  # Mark all messages as read (synchronous for immediate UI feedback)
  def mark_all_as_read!
    Inboxes::Operations::ActionsService.mark_all_as_read!(self)
  end
end

# == Schema Information
#
# Table name: inboxes
#
#  id           :uuid             not null, primary key
#  unread_count :integer          default(0), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :uuid
#
# Indexes
#
#  idx_inboxes_unread_count  (unread_count)
#  index_inboxes_on_user_id  (user_id)
#
