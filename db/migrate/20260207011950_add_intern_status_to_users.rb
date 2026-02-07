class AddInternStatusToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :is_intern, :boolean, default: true
    add_column :users, :intern_level, :integer, default: 1
    add_column :users, :intern_tasks_completed, :integer, default: 0
    add_column :users, :intern_graduated, :boolean, default: false
    add_column :users, :allow_dashboard_access, :boolean, default: false
  end
end
