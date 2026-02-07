class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [ :show, :destroy, :update_balance, :toggle_dashboard_access, :reset_intern, :toggle_suspend ]

  def index
    @users = User.all.order(created_at: :desc)
  end

  def top_earners
    @top_users = User.where.not(balance: nil)
                     .order(balance: :desc)
                     .limit(100)

    # Calculate statistics
    @total_users = User.count
    @total_balance = User.sum(:balance)
    @average_balance = @total_balance / [ @total_users, 1 ].max
    @top_10_balance = @top_users.limit(10).sum(:balance)
  end

  def show
    # Completed Tasks Statistics
    @completed_tasks = @user.user_tasks.where(approved: true)
    @pending_tasks = @user.user_tasks.where(approved: false)
    @total_tasks = @user.user_tasks.count

    # Social Tasks Statistics
    @approved_social_tasks = @user.social_task_proofs.where(status: "approved")
    @pending_social_tasks = @user.social_task_proofs.where(status: "pending")
    @rejected_social_tasks = @user.social_task_proofs.where(status: "rejected")
    @total_social_tasks = @user.social_task_proofs.count

    # Learn and Earn Statistics
    @approved_learn_and_earns = @user.learn_and_earns.where(status: "approved")
    @pending_learn_and_earns = @user.learn_and_earns.where(status: "pending")
    @total_learn_and_earns = @user.learn_and_earns.count

    # Clicks/CAPTCHA Statistics
    @total_clicks = @user.clicks.count
    @recent_clicks = @user.clicks.includes(:link).order(created_at: :desc).limit(10)

    # Financial Statistics
    @total_earned = @user.total_earned || 0
    @wallet_balance = @user.wallet_balance || 0
    @referral_balance = @user.referral_balance || 0
    @total_balance = @user.balance || 0

    # Withdrawal Statistics
    @total_withdrawals = @user.withdrawals.count
    @pending_withdrawals = @user.withdrawals.where(status: "pending").count
    @approved_withdrawals = @user.withdrawals.where(status: "approved").sum(:amount)
    @recent_withdrawals = @user.withdrawals.order(created_at: :desc).limit(5)

    # Referral Statistics
    @total_referrals = @user.referrals_made.where(claimed: true).count
    @pending_referrals = @user.referrals_made.where(claimed: false).count
    @referral_earnings = @user.referral_balance || 0
    @recent_referrals = @user.referrals_made.includes(:referred_user).order(created_at: :desc).limit(10)

    # Transaction History
    @recent_transactions = @user.transactions.order(created_at: :desc).limit(10)

    # Activity Timeline
    @last_active = @user.last_active_at || @user.updated_at
  end

  def destroy
    @user.destroy
    redirect_to admin_users_path, notice: "User was successfully deleted."
  end

  def update_balance
    new_balance = params[:balance].to_f
    old_balance = @user.balance || 0

    if @user.update(balance: new_balance)
      # Create transaction record for balance change
      amount_change = new_balance - old_balance
      @user.transactions.create!(
        amount: amount_change.abs,
        transaction_type: amount_change >= 0 ? "credit" : "debit",
        description: "Admin balance adjustment: #{old_balance} → #{new_balance}"
      )

      redirect_back fallback_location: admin_users_path, notice: "Balance updated successfully to $#{new_balance}"
    else
      redirect_back fallback_location: admin_users_path, alert: "Failed to update balance"
    end
  end

  # Toggle dashboard access for interns
  def toggle_dashboard_access
    new_status = !@user.allow_dashboard_access

    if @user.update(allow_dashboard_access: new_status)
      status_text = new_status ? "granted" : "revoked"
      redirect_back fallback_location: admin_user_path(@user), notice: "Dashboard access #{status_text} successfully."
    else
      redirect_back fallback_location: admin_user_path(@user), alert: "Failed to update dashboard access."
    end
  end

  # Reset intern status
  def reset_intern
    if @user.update(
      is_intern: true,
      intern_level: 1,
      intern_tasks_completed: 0,
      intern_graduated: false,
      allow_dashboard_access: false
    )
      redirect_back fallback_location: admin_user_path(@user), notice: "Intern status reset successfully."
    else
      redirect_back fallback_location: admin_user_path(@user), alert: "Failed to reset intern status."
    end
  end

  # Toggle suspend/unsuspend user
  def toggle_suspend
    @user.suspended = !@user.suspended
    if @user.save
      status = @user.suspended ? "suspended" : "unsuspended"
      redirect_back fallback_location: admin_user_path(@user), notice: "User successfully #{status}."
    else
      redirect_back fallback_location: admin_user_path(@user), alert: "Failed to change suspend status."
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end
