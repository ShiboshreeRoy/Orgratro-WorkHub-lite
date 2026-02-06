class CreateAchievements < ActiveRecord::Migration[7.2]
  def change
    create_table :achievements do |t|
      t.string :name
      t.text :description
      t.string :badge_image
      t.integer :points
      t.string :achievement_type
      t.boolean :is_active

      t.timestamps
    end
  end
end
