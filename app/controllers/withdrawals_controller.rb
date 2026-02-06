class WithdrawalsController < ApplicationController
  before_action :set_withdrawal, only: %i[ show edit update update_status ]

  # GET /withdrawals or /withdrawals.json
 def index
  @withdrawals = current_user.admin? ? Withdrawal.all.includes(:user) : current_user.withdrawals
end

def new
  @withdrawal = Withdrawal.new
end

def create
  @withdrawal = current_user.withdrawals.build(withdrawal_params)
  
  # Use database-level locking to prevent race conditions
  current_user.class.where(id: current_user.id).lock(true).first
  
  current_user.reload
  if @withdrawal.amount <= current_user.balance
    @withdrawal.status = "pending"
    current_user.with_lock do
      # Check balance again inside the lock to ensure consistency
      if @withdrawal.amount <= current_user.balance
        current_user.balance -= @withdrawal.amount
        Withdrawal.transaction do
          # Skip the balance validation since we've already verified it
          @withdrawal.save(validate: false)
          current_user.save!
          # Create transaction record for the withdrawal
          @withdrawal.user.transactions.create!(
            amount: @withdrawal.amount,
            transaction_type: 'debit',
            description: "Withdrawal request of $#{@withdrawal.amount}"
          )
        end
        redirect_to withdrawals_path, notice: "Withdrawal requested."
      else
        flash.now[:alert] = "Insufficient balance."
        render :new
      end
    end
  else
    flash.now[:alert] = "Insufficient balance."
    render :new
  end
end


def update_status
  if current_user.admin? && @withdrawal.status == "pending"
    if params[:status] == 'approved'
      if @withdrawal.update_columns(status: "approved")
        # Create transaction record for the approved withdrawal
        @withdrawal.user.transactions.create!(
          amount: @withdrawal.amount,
          transaction_type: 'debit',
          description: "Withdrawal approved and processed: $#{@withdrawal.amount}"
        )
        redirect_to withdrawals_path, notice: "Withdrawal approved."
      else
        redirect_to withdrawals_path, alert: "Failed to approve withdrawal."
      end
    elsif params[:status] == 'rejected'
      if @withdrawal.update_columns(status: "rejected")
        # Restore the withdrawn amount back to user's balance
        @withdrawal.user.update!(balance: @withdrawal.user.balance + @withdrawal.amount)
        # Create transaction record for the rejection
        @withdrawal.user.transactions.create!(
          amount: @withdrawal.amount,
          transaction_type: 'credit',
          description: "Withdrawal rejected and amount refunded: $#{@withdrawal.amount}"
        )
        redirect_to withdrawals_path, notice: "Withdrawal rejected."
      else
        redirect_to withdrawals_path, alert: "Failed to reject withdrawal."
      end
    else
      redirect_to withdrawals_path, alert: "Invalid action."
    end
  else
    redirect_to withdrawals_path, alert: "Action not allowed."
  end
end

# Keep the original update method for other update operations
def update
  # Redirect to the show page by default
  redirect_to withdrawal_path(@withdrawal)
end

def set_withdrawal
  @withdrawal = Withdrawal.find(params[:id])
end

private

def withdrawal_params
  params.require(:withdrawal).permit(:amount, :payment_method, :payment_details)
end

end