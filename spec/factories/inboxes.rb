# frozen_string_literal: true

FactoryBot.define do
  factory :inbox do
    association :user
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
