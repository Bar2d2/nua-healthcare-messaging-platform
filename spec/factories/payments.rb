# frozen_string_literal: true

FactoryBot.define do
  factory :payment do
    association :user
    amount { 100.0 }
    status { :pending }

    trait :pending do
      status { :pending }
    end

    trait :successful do
      status { :successful }
    end

    trait :failed do
      status { :failed }
      error_message { 'Payment failed' }
    end
  end
end

# == Schema Information
#
# Table name: payments
#
#  id               :uuid             not null, primary key
#  amount           :decimal(8, 2)    default(0.0), not null
#  error_message    :text
#  last_retry_at    :datetime
#  payment_provider :string           default("flaky"), not null
#  retry_count      :integer          default(0), not null
#  status           :integer          default("pending"), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_id          :uuid
#
# Indexes
#
#  idx_payments_status_retry_created        (status,retry_count,created_at)
#  idx_payments_user_status_created         (user_id,status,created_at)
#  index_payments_on_retry_count            (retry_count)
#  index_payments_on_status_and_created_at  (status,created_at)
#  index_payments_on_user_id                (user_id)
#  index_payments_on_user_id_and_status     (user_id,status)
#
