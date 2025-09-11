class AddUnreadMessageTracking < ActiveRecord::Migration[7.2]
  def change
    # Add unread_count to inboxes table
    add_column :inboxes, :unread_count, :integer, default: 0, null: false

    # Add read_at timestamp to messages table
    add_column :messages, :read_at, :datetime

    # Add performance indexes for unread count queries
    add_index :inboxes, :unread_count, name: 'idx_inboxes_unread_count'
    add_index :messages, :read_at, name: 'idx_messages_read_at'

    # Add partial indexes for unread messages (performance optimization)
    add_index :messages, [:inbox_id, :read_at],
              name: 'idx_messages_inbox_unread',
              where: 'read_at IS NULL'

    add_index :messages, [:inbox_id, :read],
              name: 'idx_messages_inbox_read_status',
              where: 'read = false'

    # Add composite index for unread count queries
    add_index :messages, [:inbox_id, :read, :created_at],
              name: 'idx_messages_inbox_unread_created',
              order: { created_at: :desc }
  end
end
