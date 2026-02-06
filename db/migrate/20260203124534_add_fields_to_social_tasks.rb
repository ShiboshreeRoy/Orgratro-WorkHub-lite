class AddFieldsToSocialTasks < ActiveRecord::Migration[7.2]
  def change
    add_column :social_tasks, :url, :string
    add_column :social_tasks, :image, :string
    add_column :social_tasks, :description, :text
  end
end
