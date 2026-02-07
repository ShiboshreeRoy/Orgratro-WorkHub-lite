class CreateInternTaskCompletions < ActiveRecord::Migration[7.2]
  def change
    create_table :intern_task_completions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :intern_task, null: false, foreign_key: true
      t.string :status
      t.text :proof

      t.timestamps
    end
  end
end
