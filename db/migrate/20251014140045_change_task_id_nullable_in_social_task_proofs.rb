class ChangeTaskIdNullableInSocialTaskProofs < ActiveRecord::Migration[7.0]
  def change
    change_column_null :social_task_proofs, :task_id, true
  end
end
