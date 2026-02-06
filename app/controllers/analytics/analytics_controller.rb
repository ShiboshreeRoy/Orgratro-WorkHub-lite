class Analytics::AnalyticsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!

  def dashboard
    @total_users = User.count
    @active_users_today = User.where(
      "last_active_at >= ?", 
      Date.current.beginning_of_day
    ).count
    @pending_withdrawals = Withdrawal.pending.count
    @total_earnings = User.sum(:balance) + User.sum(:referral_balance)
    
    # Get recent analytics snapshots
    @recent_analytics = AnalyticsSnapshot.recent_analytics(7)
    
    # Calculate task completion rate
    total_tasks = Task.count
    completed_tasks = UserTask.where(approved: true).count
    @task_completion_rate = total_tasks > 0 ? (completed_tasks.to_f / total_tasks * 100).round(2) : 0.0
    
    # Get referral statistics
    @total_referrals = Referral.count
    @successful_referrals = Referral.joins(:referred_user).where(users: { suspended: false }).count
    @referral_conversion_rate = @total_users > 0 ? (@successful_referrals.to_f / @total_users * 100).round(2) : 0.0
    
    # Recent activities
    @recent_activities = UserActivityLog.includes(:user).recent.limit(10)
    
    # Top active users
    @top_active_users = UserActivityLog.top_active_users.map do |user_id, count|
      user = User.find_by(id: user_id)
      { user: user, count: count } if user
    end.compact.first(5)
  end

  def user_analytics
    @users = User.includes(:user_activity_logs).page(params[:page]).per(20)
    
    respond_to do |format|
      format.html
      format.csv { send_data generate_user_analytics_csv, filename: "user_analytics_#{Date.today}.csv" }
    end
  end

  def financial_analytics
    @total_revenue = User.sum(:balance) + User.sum(:referral_balance)
    @pending_payouts = Withdrawal.pending.sum(:amount)
    @completed_payouts = Withdrawal.approved.sum(:amount)
    
    # Daily earnings chart data
    @daily_earnings = Link.joins(:clicks).group("DATE(clicks.created_at)").sum(:earnings)
    
    # Monthly earnings
    @monthly_earnings = Link.joins(:clicks).group("DATE_TRUNC('month', clicks.created_at)").sum(:earnings)
    
    # Withdrawal analytics
    @withdrawal_stats = {
      total_requests: Withdrawal.count,
      pending: Withdrawal.pending.count,
      approved: Withdrawal.approved.count,
      rejected: Withdrawal.rejected.count
    }
  end

  def task_analytics
    @total_tasks = Task.count
    @completed_tasks = UserTask.where(approved: true).count
    @pending_tasks = UserTask.where(approved: false).count
    @task_completion_rate = @total_tasks > 0 ? (@completed_tasks.to_f / @total_tasks * 100).round(2) : 0.0
    
    # Task completion by day
    @task_completions_by_day = UserTask.where(approved: true)
                                      .group("DATE(updated_at)")
                                      .count
    
    # Task types distribution
    @task_types = Task.group(:task_type).count rescue {}
    
    # Top performers
    @top_performers = User.joins(:user_tasks)
                         .where(user_tasks: { approved: true })
                         .group('users.id')
                         .count
                         .sort_by { |_, count| -count }
                         .first(10)
                         .map { |user_id, count| [User.find(user_id), count] }
  end

  def referral_analytics
    @total_referrals = Referral.count
    @active_referrals = Referral.joins(:referred_user).where(users: { suspended: false }).count
    @referral_conversion_rate = User.count > 0 ? (@active_referrals.to_f / User.count * 100).round(2) : 0.0
    
    # Referral earnings
    @referral_earnings = Referral.sum(:reward_amount)
    
    # Referral signups by day
    @referral_signups_by_day = Referral.group("DATE(created_at)").count
    
    # Top referrers
    @top_referrers = User.joins(:referrals_made)
                        .group('users.id')
                        .count
                        .sort_by { |_, count| -count }
                        .first(10)
                        .map { |user_id, count| [User.find(user_id), count] }
  end

  private

  def generate_user_analytics_csv
    require 'csv'
    
    CSV.generate(headers: true) do |csv|
      csv << ['User ID', 'Email', 'Role', 'Balance', 'Referral Balance', 'Total Clicks', 
              'Tasks Completed', 'Created At', 'Last Active', 'Total Activities']
      
      @users.each do |user|
        csv << [
          user.id,
          user.email,
          user.role,
          user.balance,
          user.referral_balance,
          user.total_clicks || 0,
          user.tasks_completed || 0,
          user.created_at,
          user.last_active_at,
          user.user_activity_logs.count
        ]
      end
    end
  end
end