class UserDashbordController < ApplicationController
  before_action :authenticate_user!
  before_action :check_dashboard_access

  def index
    @user = User.all
    @links = Link.all
    @approved_tasks = UserTask.where(approved: true)
    @total_clicks = current_user.clicks.count
    @total_earned = current_user.total_earned
    @withdrawals = current_user.withdrawals

    @total_proofs = current_user.social_task_proofs.count
    @approved_proofs = current_user.social_task_proofs.where(status: "approved").count
     @total_referrals = current_user.referrals_made.where(claimed: true).count

    # Social tasks data
    @available_tasks = SocialTask.all
    @user_proofs = current_user.social_task_proofs.includes(:social_task).where.not(task_id: nil).order(created_at: :desc).limit(5)
  end

  private

  def check_dashboard_access
    # Redirect interns to intern dashboard
    unless current_user.can_access_dashboard?
      redirect_to intern_dashboard_path, alert: "Please complete your intern training to access the full dashboard."
    end
  end
end
