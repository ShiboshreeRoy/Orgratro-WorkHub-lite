class AddEnhancedProfileFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :bio, :text
    add_column :users, :country, :string
    add_column :users, :timezone, :string
    add_column :users, :contact_method, :string
    add_column :users, :service_categories, :text
    add_column :users, :seo_services, :text
    add_column :users, :traffic_source, :text
    add_column :users, :survey_promotion_methods, :text
    add_column :users, :design_services, :text
    add_column :users, :portfolio_links, :text
    add_column :users, :pricing_packages, :text
    add_column :users, :service_policy, :text
  end
end
