class CreateUserPromotionalCodes < ActiveRecord::Migration[7.2]
  def change
    create_table :user_promotional_codes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :promotional_code, null: false, foreign_key: true

      t.timestamps
    end
  end
end
