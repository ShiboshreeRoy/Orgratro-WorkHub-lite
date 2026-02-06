class AnalyticsSnapshot < ApplicationRecord
  serialize :user_acquisition_trend, coder: JSON
  serialize :revenue_data, coder: JSON
  
  validates :date, presence: true, uniqueness: { scope: :snapshot_type }
  validates :total_users, :active_users_today, :pending_withdrawals, numericality: { greater_than_or_equal_to: 0 }
  validates :task_completion_rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  scope :daily, -> { where(snapshot_type: 'daily') }
  scope :weekly, -> { where(snapshot_type: 'weekly') }
  scope :monthly, -> { where(snapshot_type: 'monthly') }
  scope :recent, -> { order(date: :desc) }

  # Calculate and save daily analytics snapshot
  def self.generate_daily_snapshot
    today = Date.current
    
    # Check if a snapshot for today already exists
    return if find_by(date: today, snapshot_type: 'daily')
    
    # Calculate metrics
    total_users = User.count
    active_users_today = User.where(
      "last_active_at >= ? AND last_active_at <= ?", 
      today.beginning_of_day, 
      today.end_of_day
    ).count
    
    total_earnings = User.sum(:balance) + User.sum(:referral_balance)
    pending_withdrawals = Withdrawal.pending.count
    
    # Calculate task completion rate
    total_tasks = Task.count
    completed_tasks = UserTask.where(approved: true).count
    task_completion_rate = total_tasks > 0 ? (completed_tasks.to_f / total_tasks * 100).round(2) : 0.0
    
    # Calculate user acquisition trend (last 30 days)
    user_acquisition_trend = {}
    30.downto(0) do |i|
      date = today - i.days
      user_acquisition_trend[date.strftime('%Y-%m-%d')] = User.where(
        "created_at >= ? AND created_at <= ?", 
        date.beginning_of_day, 
        date.end_of_day
      ).count
    end

    # Calculate revenue data
    revenue_data = {
      today_clicks: Click.where(created_at: today.all_day).count,
      today_earnings: Click.where(created_at: today.all_day).sum(:earnings).to_f,
      yesterday_clicks: Click.where(created_at: (today - 1.day).all_day).count,
      yesterday_earnings: Click.where(created_at: (today - 1.day).all_day).sum(:earnings).to_f
    }

    # Create the snapshot
    create!(
      date: today,
      snapshot_type: 'daily',
      total_users: total_users,
      active_users_today: active_users_today,
      total_earnings: total_earnings,
      pending_withdrawals: pending_withdrawals,
      task_completion_rate: task_completion_rate,
      user_acquisition_trend: user_acquisition_trend,
      revenue_data: revenue_data
    )
  end

  # Get recent analytics data for charts
  def self.recent_analytics(limit = 30)
    daily.recent.limit(limit).reverse
  end

  # Get weekly summary for the given month
  def self.weekly_summary(year, month)
    where(
      "snapshot_type = 'daily' AND EXTRACT(YEAR FROM date) = ? AND EXTRACT(MONTH FROM date) = ?",
      year, month
    ).group("DATE_TRUNC('week', date)").sum(:active_users_today)
  end

  # Get monthly summary
  def self.monthly_summary
    where(snapshot_type: 'daily')
      .group("DATE_TRUNC('month', date)")
      .average(:total_users)
  end
end