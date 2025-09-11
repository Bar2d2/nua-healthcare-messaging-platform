# frozen_string_literal: true

FactoryBot.define do
  factory :message do
    sequence(:body) { |n| "This is test message #{n}" }
    read { false }
    status { :sent }
    routing_type { :direct }
    association :inbox
    association :outbox

    trait :read do
      read { true }
      status { :read }
    end

    trait :unread do
      read { false }
      status { :sent }
    end

    trait :delivered do
      status { :delivered }
    end

    trait :sent do
      status { :sent }
    end

    trait :direct do
      routing_type { :direct }
    end

    trait :reply do
      routing_type { :reply }
      association :parent_message
    end

    trait :auto do
      routing_type { :auto }
    end

    trait :long_message do
      body do
        base = 'This is a long message used for testing edge cases. '
        base * 20
      end
    end
  end
end

# == Schema Information
#
# Table name: messages
#
#  id                :uuid             not null, primary key
#  body              :text
#  read              :boolean          default(FALSE), not null
#  read_at           :datetime
#  routing_type      :integer          default("direct"), not null
#  status            :integer          default("sent"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  inbox_id          :uuid
#  outbox_id         :uuid
#  parent_message_id :uuid
#  prescription_id   :uuid
#
# Indexes
#
#  idx_messages_inbox_created_at                     (inbox_id,created_at DESC)
#  idx_messages_inbox_prescription_created           (inbox_id,prescription_id,created_at)
#  idx_messages_inbox_read_status                    (inbox_id,read) WHERE (read = false)
#  idx_messages_inbox_unread                         (inbox_id,read_at) WHERE (read_at IS NULL)
#  idx_messages_inbox_unread_created                 (inbox_id,read,created_at DESC)
#  idx_messages_outbox_created_at                    (outbox_id,created_at DESC)
#  idx_messages_parent_thread                        (parent_message_id,created_at DESC)
#  idx_messages_read_at                              (read_at)
#  idx_messages_root_conversations                   (parent_message_id,created_at DESC) WHERE (parent_message_id IS NULL)
#  idx_messages_routing_type                         (routing_type)
#  idx_messages_status_read                          (status,read)
#  index_messages_on_inbox_id                        (inbox_id)
#  index_messages_on_outbox_id                       (outbox_id)
#  index_messages_on_parent_message_id               (parent_message_id)
#  index_messages_on_prescription_id                 (prescription_id)
#  index_messages_on_prescription_id_and_created_at  (prescription_id,created_at)
#  index_messages_on_routing_type                    (routing_type)
#  index_messages_on_routing_type_and_created_at     (routing_type,created_at)
#  index_messages_on_status                          (status)
#  index_messages_on_status_and_created_at           (status,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (parent_message_id => messages.id) ON DELETE => nullify
#  fk_rails_...  (prescription_id => prescriptions.id)
#
