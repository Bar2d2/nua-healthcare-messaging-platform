class AddPrescriptionToMessages < ActiveRecord::Migration[7.2]
  def change
    # Add prescription relationship to messages
    add_reference :messages, :prescription, null: true, foreign_key: true, type: :uuid

    # Performance indexes for message-prescription relationships (prescription_id index auto-created by add_reference)
    add_index :messages, [:prescription_id, :created_at]
    add_index :messages, [:inbox_id, :prescription_id, :created_at], name: 'idx_messages_inbox_prescription_created'

    # Performance indexes for prescription workflows
    add_index :prescriptions, [:user_id, :status, :created_at], name: 'idx_prescriptions_user_status_created'

    # Performance indexes for payment workflows
    add_index :payments, [:status, :retry_count, :created_at], name: 'idx_payments_status_retry_created'
    add_index :payments, [:user_id, :status, :created_at], name: 'idx_payments_user_status_created'
  end
end
