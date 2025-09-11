# frozen_string_literal: true

FactoryBot.define do
  factory :outbox do
    association :user
  end
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
