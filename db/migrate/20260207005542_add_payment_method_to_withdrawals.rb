class AddPaymentMethodToWithdrawals < ActiveRecord::Migration[7.2]
  def change
    add_column :withdrawals, :payment_method, :string
  end
end
