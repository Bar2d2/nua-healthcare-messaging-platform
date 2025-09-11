class CreateUsersMessagesInboxesOutboxesAndPayments < ActiveRecord::Migration[7.2]
  def change
    # Enable UUID extension for PostgreSQL
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')

    create_table :users, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.boolean :is_patient, default: true, null: false
      t.boolean :is_doctor, default: false, null: false
      t.boolean :is_admin, default: false, null: false
      t.string :first_name
      t.string :last_name

      t.timestamps
    end

    create_table :messages, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.text :body
      t.uuid :outbox_id
      t.uuid :inbox_id
      t.boolean :read, default: false, null: false

      t.timestamps
    end

    create_table :inboxes, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.uuid :user_id

      t.timestamps
    end

    create_table :outboxes, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.uuid :user_id

      t.timestamps
    end

    create_table :payments, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.uuid :user_id

      t.timestamps
    end

    add_index :inboxes, :user_id
    add_index :outboxes, :user_id
    add_index :payments, :user_id
    add_index :messages, :outbox_id
    add_index :messages, :inbox_id
  end
end
