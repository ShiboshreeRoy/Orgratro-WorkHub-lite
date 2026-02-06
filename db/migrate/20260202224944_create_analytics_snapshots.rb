class CreateAnalyticsSnapshots < ActiveRecord::Migration[7.2]
  def change
    create_table :analytics_snapshots do |t|
      t.date :date
      t.integer :total_users
      t.integer :active_users_today
      t.decimal :total_earnings
      t.integer :pending_withdrawals
      t.decimal :task_completion_rate
      t.text :user_acquisition_trend
      t.text :revenue_data

      t.timestamps
    end
  end
end
