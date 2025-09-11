class CreatePrescriptions < ActiveRecord::Migration[7.2]
  def change
    create_table :prescriptions, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.integer :status, null: false, default: 0
      t.string :pdf_url
      t.datetime :requested_at, null: false
      t.datetime :ready_at
      t.references :payment, null: true, foreign_key: true, type: :uuid

      t.timestamps
    end

    # Performance indexes
    add_index :prescriptions, [:user_id, :status]
    add_index :prescriptions, [:user_id, :created_at]
    add_index :prescriptions, :status
    add_index :prescriptions, :requested_at
  end
end
