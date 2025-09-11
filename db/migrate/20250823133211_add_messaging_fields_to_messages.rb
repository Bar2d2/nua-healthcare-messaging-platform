class AddMessagingFieldsToMessages < ActiveRecord::Migration[7.2]
  def change
    add_column :messages, :status, :integer, default: 0, null: false
    add_column :messages, :routing_type, :integer, default: 0, null: false
    add_column :messages, :parent_message_id, :uuid, null: true

    add_index :messages, :status
    add_index :messages, :routing_type
    add_index :messages, :parent_message_id
    add_index :messages, [:status, :created_at]
    add_index :messages, [:routing_type, :created_at]

    add_foreign_key :messages, :messages, column: :parent_message_id, on_delete: :nullify
  end
end
