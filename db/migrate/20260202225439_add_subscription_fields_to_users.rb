class AddSubscriptionFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_reference :users, :subscription_plan, null: true, foreign_key: true
    add_column :users, :subscription_start_date, :datetime
    add_column :users, :subscription_end_date, :datetime
    add_column :users, :is_subscribed, :boolean, default: false
    
    # Update existing users to have is_subscribed = false by default
    User.update_all(is_subscribed: false) if User.table_exists?
  end
end
