class UserDashbordController < ApplicationController
  before_action :authenticate_user!
  def index
    @user = User.all
    @links = Link.all
   @approved_tasks = UserTask.where(approved: true)
    @total_clicks = current_user.clicks.count
    @total_earned = current_user.total_earned
    @withdrawals = current_user.withdrawals

    @total_proofs = current_user.social_task_proofs.count
    @approved_proofs = current_user.social_task_proofs.where(status: 'approved').count
     @total_referrals = current_user.sent_referrals.count
    
  end
end
