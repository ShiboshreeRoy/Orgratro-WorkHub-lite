class CreateShortLinks < ActiveRecord::Migration[7.2]
  def change
    create_table :short_links do |t|
      t.string :original
      t.string :slug

      t.timestamps
    end
    add_index :short_links, :slug
  end
end
