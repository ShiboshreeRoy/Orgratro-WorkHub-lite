class CreatePaymentGateways < ActiveRecord::Migration[7.2]
  def change
    create_table :payment_gateways do |t|
      t.string :name
      t.string :api_key
      t.string :secret_key
      t.string :environment
      t.boolean :is_active

      t.timestamps
    end
  end
end
