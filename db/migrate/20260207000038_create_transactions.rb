class CreateTransactions < ActiveRecord::Migration[7.2]
  def change
    create_table :transactions do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :amount, precision: 20, scale: 10, null: false
      t.string :transaction_type, null: false
      t.text :description

      t.timestamps
    end

    add_index :transactions, [ :user_id, :created_at ]
    add_index :transactions, :transaction_type
  end
end
