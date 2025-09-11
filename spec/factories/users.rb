# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:first_name) { |n| "John#{n}" }
    sequence(:last_name) { |n| "Doe#{n}" }
    is_patient { true }
    is_admin { false }
    is_doctor { false }

    trait :admin do
      is_patient { false }
      is_admin { true }
      is_doctor { false }
    end

    trait :doctor do
      is_patient { false }
      is_admin { false }
      is_doctor { true }
    end

    trait :patient do
      is_patient { true }
      is_admin { false }
      is_doctor { false }
    end
  end
end

# == Schema Information
#
# Table name: users
#
#  id         :uuid             not null, primary key
#  first_name :string
#  is_admin   :boolean          default(FALSE), not null
#  is_doctor  :boolean          default(FALSE), not null
#  is_patient :boolean          default(TRUE), not null
#  last_name  :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
