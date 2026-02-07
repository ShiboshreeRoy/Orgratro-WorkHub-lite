class CreateInternTasks < ActiveRecord::Migration[7.2]
  def change
    create_table :intern_tasks do |t|
      t.string :title
      t.text :description
      t.string :task_type
      t.string :video_url
      t.integer :admin_id
      t.string :status
      t.integer :priority

      t.timestamps
    end
  end
end
