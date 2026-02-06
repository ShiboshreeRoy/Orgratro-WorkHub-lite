class AddAnalyticsColumnsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :last_active_at, :datetime
    add_column :users, :total_clicks, :integer
    add_column :users, :total_earnings, :decimal
    add_column :users, :tasks_completed, :integer
    add_column :users, :referral_conversion_rate, :decimal
  end
end
