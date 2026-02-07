class AddProjectFieldsToContactMessages < ActiveRecord::Migration[7.2]
  def change
    add_column :contact_messages, :project_name, :string
    add_column :contact_messages, :project_description, :text
    add_column :contact_messages, :project_url, :string
    add_column :contact_messages, :address, :text
    add_column :contact_messages, :contact_number, :string
  end
end
