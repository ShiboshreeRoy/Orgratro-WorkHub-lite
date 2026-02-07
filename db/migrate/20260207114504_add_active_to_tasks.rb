class AddActiveToTasks < ActiveRecord::Migration[7.2]
  def change
    add_column :tasks, :active, :boolean, default: true

    # Set all existing tasks to active by default
    Task.update_all(active: true) if table_exists?(:tasks)
  end
end
