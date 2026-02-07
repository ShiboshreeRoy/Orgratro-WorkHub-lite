class RemoveEnhancedProfileFieldsFromUsers < ActiveRecord::Migration[7.2]
  def change
    remove_column :users, :bio
    remove_column :users, :country
    remove_column :users, :timezone
    remove_column :users, :contact_method
    remove_column :users, :service_categories
    remove_column :users, :seo_services
    remove_column :users, :traffic_source
    remove_column :users, :survey_promotion_methods
    remove_column :users, :design_services
    remove_column :users, :portfolio_links
    remove_column :users, :pricing_packages
    remove_column :users, :service_policy
  end
end
