class AddAdminIdToSocialTaskProofs < ActiveRecord::Migration[7.2]
  def change
    add_column :social_task_proofs, :admin_id, :integer
    add_index :social_task_proofs, :admin_id
  end
end
