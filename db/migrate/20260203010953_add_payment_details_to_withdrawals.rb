class AddPaymentDetailsToWithdrawals < ActiveRecord::Migration[7.2]
  def change
    add_column :withdrawals, :payment_details, :text
  end
end
