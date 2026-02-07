class AddActiveToLinks < ActiveRecord::Migration[7.2]
  def change
    add_column :links, :active, :boolean, default: true

    # Set all existing links to active by default
    Link.update_all(active: true) if table_exists?(:links)
  end
end
