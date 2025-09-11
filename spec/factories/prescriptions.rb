# frozen_string_literal: true

FactoryBot.define do
  factory :prescription do
    association :user, :patient
    association :payment
    status { :requested }
    requested_at { Time.current }

    trait :requested do
      status { :requested }
      pdf_url { nil }
      ready_at { nil }
    end

    trait :payment_rejected do
      status { :payment_rejected }
      pdf_url { nil }
      ready_at { nil }
    end

    trait :ready do
      status { :ready }
      pdf_url { 'https://example.com/prescription.pdf' }
      ready_at { Time.current }
    end

    trait :with_failed_payment do
      payment_rejected
      association :payment, :failed
    end

    trait :with_pending_payment do
      requested
      association :payment, :pending
    end

    trait :with_successful_payment do
      ready
      association :payment, :successful
    end
  end
end

# == Schema Information
#
# Table name: prescriptions
#
#  id           :uuid             not null, primary key
#  pdf_url      :string
#  ready_at     :datetime
#  requested_at :datetime         not null
#  status       :integer          default("requested"), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  payment_id   :uuid
#  user_id      :uuid             not null
#
# Indexes
#
#  idx_prescriptions_user_status_created          (user_id,status,created_at)
#  index_prescriptions_on_payment_id              (payment_id)
#  index_prescriptions_on_requested_at            (requested_at)
#  index_prescriptions_on_status                  (status)
#  index_prescriptions_on_user_id                 (user_id)
#  index_prescriptions_on_user_id_and_created_at  (user_id,created_at)
#  index_prescriptions_on_user_id_and_status      (user_id,status)
#
# Foreign Keys
#
#  fk_rails_...  (payment_id => payments.id)
#  fk_rails_...  (user_id => users.id)
#
