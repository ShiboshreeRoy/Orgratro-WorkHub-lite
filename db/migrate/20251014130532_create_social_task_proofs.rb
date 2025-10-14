class CreateSocialTaskProofs < ActiveRecord::Migration[7.2]
  def change
    create_table :social_task_proofs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :post_url
      t.integer :status
      t.references :task, null: false, foreign_key: true
      t.datetime :approved_at
      t.text :notes

      t.timestamps
    end
  end
end
