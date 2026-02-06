class CreateSubscriptionPlans < ActiveRecord::Migration[7.2]
  def change
    create_table :subscription_plans do |t|
      t.string :name
      t.text :description
      t.decimal :price
      t.text :features
      t.integer :duration_days
      t.boolean :is_active

      t.timestamps
    end
  end
end
