class AddFieldsToNotifications < ActiveRecord::Migration[7.2]
  def change
    add_column :notifications, :read_at, :datetime
    add_column :notifications, :expires_at, :datetime
    add_column :notifications, :notification_type, :string
    add_column :notifications, :priority, :integer
  end
end
