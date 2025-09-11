class AddPerformanceIndexesToMessages < ActiveRecord::Migration[7.2]
  def change
    # Optimized indexes for high-volume message queries

    # Inbox queries: Most common pattern for loading user messages
    add_index :messages, [:inbox_id, :created_at],
              name: 'idx_messages_inbox_created_at',
              order: { created_at: :desc }

    # Outbox queries: For sent messages
    add_index :messages, [:outbox_id, :created_at],
              name: 'idx_messages_outbox_created_at',
              order: { created_at: :desc }

    # Thread/conversation queries: For message threading
    add_index :messages, [:parent_message_id, :created_at],
              name: 'idx_messages_parent_thread',
              order: { created_at: :desc }

    # Status and read queries: For filtering and counting
    add_index :messages, [:status, :read],
              name: 'idx_messages_status_read'

    # Routing type queries: For message routing optimization
    add_index :messages, :routing_type,
              name: 'idx_messages_routing_type'

    # User inbox/outbox relationships: For joins optimization
    add_index :inboxes, :user_id,
              name: 'idx_inboxes_user_id' unless index_exists?(:inboxes, :user_id)

    add_index :outboxes, :user_id,
              name: 'idx_outboxes_user_id' unless index_exists?(:outboxes, :user_id)

    # Compound index for root conversations (no parent + recent first)
    add_index :messages, [:parent_message_id, :created_at],
              where: 'parent_message_id IS NULL',
              name: 'idx_messages_root_conversations',
              order: { created_at: :desc }
  end
end
