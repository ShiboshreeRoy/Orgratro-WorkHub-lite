class CreatePromotionalCodes < ActiveRecord::Migration[7.2]
  def change
    create_table :promotional_codes do |t|
      t.string :code
      t.text :description
      t.decimal :discount_percent
      t.decimal :discount_fixed_amount
      t.integer :usage_limit
      t.integer :times_used
      t.datetime :expires_at
      t.boolean :is_active

      t.timestamps
    end
  end
end
