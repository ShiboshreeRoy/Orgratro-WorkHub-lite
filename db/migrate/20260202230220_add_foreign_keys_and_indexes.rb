class AddForeignKeysAndIndexes < ActiveRecord::Migration[7.2]
  def change
    # Add indexes for better performance
    add_index :user_achievements, [:user_id, :achievement_id], unique: true unless index_exists?(:user_achievements, [:user_id, :achievement_id])
    add_index :user_achievements, :unlocked unless index_exists?(:user_achievements, :unlocked)
    add_index :user_achievements, :earned_at unless index_exists?(:user_achievements, :earned_at)
    
    add_index :user_activity_logs, :user_id unless index_exists?(:user_activity_logs, :user_id)
    add_index :user_activity_logs, :action unless index_exists?(:user_activity_logs, :action)
    add_index :user_activity_logs, :timestamp unless index_exists?(:user_activity_logs, :timestamp)
    add_index :user_activity_logs, [:user_id, :action] unless index_exists?(:user_activity_logs, [:user_id, :action])
    
    add_index :analytics_snapshots, :date unless index_exists?(:analytics_snapshots, :date)
    # Note: snapshot_type index will be added in the separate migration that creates the column
    
    add_index :promotional_codes, :code, unique: true unless index_exists?(:promotional_codes, :code)
    add_index :promotional_codes, :is_active unless index_exists?(:promotional_codes, :is_active)
    add_index :promotional_codes, :expires_at unless index_exists?(:promotional_codes, :expires_at)
    
    add_index :email_campaigns, :status unless index_exists?(:email_campaigns, :status)
    add_index :email_campaigns, :scheduled_at unless index_exists?(:email_campaigns, :scheduled_at)
    add_index :email_campaigns, :sent_at unless index_exists?(:email_campaigns, :sent_at)
    
    add_index :affiliate_relationships, [:user_id, :affiliate_program_id], unique: true unless index_exists?(:affiliate_relationships, [:user_id, :affiliate_program_id])
    add_index :affiliate_relationships, :status unless index_exists?(:affiliate_relationships, :status)
    add_index :affiliate_relationships, :joined_at unless index_exists?(:affiliate_relationships, :joined_at)
    
    add_index :users, :subscription_plan_id unless index_exists?(:users, :subscription_plan_id)
    add_index :users, :subscription_start_date unless index_exists?(:users, :subscription_start_date)
    add_index :users, :subscription_end_date unless index_exists?(:users, :subscription_end_date)
    add_index :users, :is_subscribed unless index_exists?(:users, :is_subscribed)
  end
end
