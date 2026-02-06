class CreateAffiliatePrograms < ActiveRecord::Migration[7.2]
  def change
    create_table :affiliate_programs do |t|
      t.string :name
      t.text :description
      t.decimal :commission_rate
      t.text :terms
      t.boolean :is_active

      t.timestamps
    end
  end
end
