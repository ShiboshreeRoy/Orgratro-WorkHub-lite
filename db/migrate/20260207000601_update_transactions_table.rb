class UpdateTransactionsTable < ActiveRecord::Migration[7.2]
  def up
    # Add constraints and precision
    change_column :transactions, :amount, :decimal, precision: 20, scale: 10
    change_column_null :transactions, :amount, false

    change_column_null :transactions, :transaction_type, false

    # Add indexes for better performance
    add_index :transactions, [ :user_id, :created_at ]
    add_index :transactions, :transaction_type
  end

  def down
    remove_index :transactions, [ :user_id, :created_at ] if index_exists?(:transactions, [ :user_id, :created_at ])
    remove_index :transactions, :transaction_type if index_exists?(:transactions, :transaction_type)

    change_column_null :transactions, :amount, true
    change_column_null :transactions, :transaction_type, true
    change_column :transactions, :amount, :decimal
  end
end
