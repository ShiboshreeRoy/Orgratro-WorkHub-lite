class ChangeUserIdNullOnNotifications < ActiveRecord::Migration[7.2]
  def change
    change_column_null :notifications, :user_id, true
  end
end
