# frozen_string_literal: true

# Represents a user's outbox for sending messages.
# Part of the inbox/outbox pattern for message routing in the medical communication system.
class Outbox < ApplicationRecord
  belongs_to :user
  has_many :messages, dependent: :destroy
end

# == Schema Information
#
# Table name: outboxes
#
#  id         :uuid             not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :uuid
#
# Indexes
#
#  index_outboxes_on_user_id  (user_id)
#
