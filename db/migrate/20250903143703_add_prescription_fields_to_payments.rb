class AddPrescriptionFieldsToPayments < ActiveRecord::Migration[7.2]
  def change
    add_column :payments, :amount, :decimal, precision: 8, scale: 2, null: false, default: 0.0
    add_column :payments, :status, :integer, null: false, default: 0
    add_column :payments, :payment_provider, :string, null: false, default: 'flaky'
    add_column :payments, :error_message, :text
    add_column :payments, :retry_count, :integer, null: false, default: 0
    add_column :payments, :last_retry_at, :datetime

    # Performance indexes for payment queries
    add_index :payments, [:user_id, :status]
    add_index :payments, [:status, :created_at]
    add_index :payments, :retry_count
  end
end
