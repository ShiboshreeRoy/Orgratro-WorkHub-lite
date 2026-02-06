class CreateAffiliateRelationships < ActiveRecord::Migration[7.2]
  def change
    create_table :affiliate_relationships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :affiliate_program, null: false, foreign_key: true
      t.decimal :commission_amount
      t.string :status
      t.datetime :joined_at

      t.timestamps
    end
  end
end
