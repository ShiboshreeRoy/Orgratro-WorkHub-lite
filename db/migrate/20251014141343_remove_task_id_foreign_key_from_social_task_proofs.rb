class RemoveTaskIdForeignKeyFromSocialTaskProofs < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key :social_task_proofs, :tasks
    change_column_null :social_task_proofs, :task_id, true
  end
end
