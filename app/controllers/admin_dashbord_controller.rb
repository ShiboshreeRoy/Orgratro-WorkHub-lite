class AdminDashbordController < ApplicationController
   before_action :authenticate_user!
   before_action :ensure_admin!

  def index
    @total_user = User.all
    @total_click = Click.all
    @total_link = Link.all
    @user_task = UserTask.all
    @referrals = Referral.all   
    @recent_users = User.order(created_at: :desc).limit(5)
    @users_with_balance = User.limit(10).order(balance: :desc) # Top 10 users by balance
    @total_balance = User.sum(:balance) # Total balance across all users
    @avg_balance = User.average(:balance) || 0.0 # Average balance
    # @total_withdrawals = Withdrawal.sum(:amount)
    
    # Add pending learn_and_earns for approval
    @pending_learn_and_earns = LearnAndEarn.where(status: 'pending').includes(:user).order(created_at: :desc).limit(10)
    
    # Add social tasks for quick overview
    @social_tasks = SocialTask.order(created_at: :desc).limit(5)
  end
end
