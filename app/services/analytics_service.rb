class AnalyticsService
  def initialize
    @date = Date.current
  end

  # Generate daily analytics snapshot
  def generate_daily_snapshot
    # Check if snapshot already exists for today
    existing_snapshot = AnalyticsSnapshot.find_by(date: @date, snapshot_type: 'daily')
    return existing_snapshot if existing_snapshot

    # Calculate metrics
    total_users = User.count
    active_users_today = calculate_active_users_today
    total_earnings = calculate_total_earnings
    pending_withdrawals = Withdrawal.pending.count
    task_completion_rate = calculate_task_completion_rate
    user_acquisition_trend = calculate_user_acquisition_trend
    revenue_data = calculate_revenue_data

    # Create the snapshot
    AnalyticsSnapshot.create!(
      date: @date,
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

  # Calculate active users for today
  def calculate_active_users_today
    User.where(
      "last_active_at >= ? AND last_active_at <= ?", 
      @date.beginning_of_day, 
      @date.end_of_day
    ).count
  end

  # Calculate total earnings across all users
  def calculate_total_earnings
    User.sum(:balance) + User.sum(:referral_balance)
  end

  # Calculate task completion rate
  def calculate_task_completion_rate
    total_tasks = Task.count
    completed_tasks = UserTask.where(approved: true).count
    total_tasks > 0 ? (completed_tasks.to_f / total_tasks * 100).round(2) : 0.0
  end

  # Calculate user acquisition trend (last 30 days)
  def calculate_user_acquisition_trend
    user_acquisition_trend = {}
    30.downto(0) do |i|
      date = @date - i.days
      user_acquisition_trend[date.strftime('%Y-%m-%d')] = User.where(
        "created_at >= ? AND created_at <= ?", 
        date.beginning_of_day, 
        date.end_of_day
      ).count
    end
    user_acquisition_trend
  end

  # Calculate revenue data
  def calculate_revenue_data
    {
      today_clicks: Click.where(created_at: @date.all_day).count,
      today_earnings: Click.where(created_at: @date.all_day).sum(:earnings).to_f,
      yesterday_clicks: Click.where(created_at: (@date - 1.day).all_day).count,
      yesterday_earnings: Click.where(created_at: (@date - 1.day).all_day).sum(:earnings).to_f
    }
  end

  # Generate weekly analytics snapshot
  def generate_weekly_snapshot
    week_start = @date.beginning_of_week
    week_end = @date.end_of_week

    # Check if snapshot already exists for this week
    existing_snapshot = AnalyticsSnapshot.find_by(
      date: week_start, 
      snapshot_type: 'weekly'
    )
    return existing_snapshot if existing_snapshot

    # Calculate metrics for the week
    total_users = User.where(created_at: week_start..week_end).count
    active_users_this_week = User.where(
      last_active_at: week_start..week_end
    ).count
    total_earnings = calculate_total_earnings_for_period(week_start, week_end)
    pending_withdrawals = Withdrawal.where(created_at: week_start..week_end).pending.count
    task_completion_rate = calculate_task_completion_rate_for_period(week_start, week_end)

    # Create the snapshot
    AnalyticsSnapshot.create!(
      date: week_start,
      snapshot_type: 'weekly',
      total_users: total_users,
      active_users_today: active_users_this_week,
      total_earnings: total_earnings,
      pending_withdrawals: pending_withdrawals,
      task_completion_rate: task_completion_rate,
      user_acquisition_trend: {},
      revenue_data: {}
    )
  end

  # Calculate total earnings for a specific period
  def calculate_total_earnings_for_period(start_date, end_date)
    User.where(created_at: start_date..end_date).sum(:balance) + 
    User.where(created_at: start_date..end_date).sum(:referral_balance)
  end

  # Calculate task completion rate for a specific period
  def calculate_task_completion_rate_for_period(start_date, end_date)
    total_tasks = Task.where(created_at: start_date..end_date).count
    completed_tasks = UserTask.where(
      approved: true, 
      created_at: start_date..end_date
    ).count
    total_tasks > 0 ? (completed_tasks.to_f / total_tasks * 100).round(2) : 0.0
  end

  # Generate monthly analytics snapshot
  def generate_monthly_snapshot
    month_start = @date.beginning_of_month
    month_end = @date.end_of_month

    # Check if snapshot already exists for this month
    existing_snapshot = AnalyticsSnapshot.find_by(
      date: month_start, 
      snapshot_type: 'monthly'
    )
    return existing_snapshot if existing_snapshot

    # Calculate metrics for the month
    total_users = User.where(created_at: month_start..month_end).count
    active_users_this_month = User.where(
      last_active_at: month_start..month_end
    ).count
    total_earnings = calculate_total_earnings_for_period(month_start, month_end)
    pending_withdrawals = Withdrawal.where(created_at: month_start..month_end).pending.count
    task_completion_rate = calculate_task_completion_rate_for_period(month_start, month_end)

    # Create the snapshot
    AnalyticsSnapshot.create!(
      date: month_start,
      snapshot_type: 'monthly',
      total_users: total_users,
      active_users_today: active_users_this_month,
      total_earnings: total_earnings,
      pending_withdrawals: pending_withdrawals,
      task_completion_rate: task_completion_rate,
      user_acquisition_trend: {},
      revenue_data: {}
    )
  end

  # Get dashboard analytics summary
  def dashboard_analytics
    {
      total_users: User.count,
      active_users_today: calculate_active_users_today,
      pending_withdrawals: Withdrawal.pending.count,
      total_earnings: calculate_total_earnings,
      task_completion_rate: calculate_task_completion_rate,
      total_referrals: Referral.count,
      successful_referrals: Referral.joins(:referred_user).where(users: { suspended: false }).count,
      referral_conversion_rate: calculate_referral_conversion_rate
    }
  end

  # Calculate referral conversion rate
  def calculate_referral_conversion_rate
    total_users = User.count
    successful_referrals = Referral.joins(:referred_user).where(users: { suspended: false }).count
    total_users > 0 ? (successful_referrals.to_f / total_users * 100).round(2) : 0.0
  end

  # Get user activity statistics
  def user_activity_stats(user)
    {
      total_clicks: user.clicks.count,
      tasks_completed: user.user_tasks.where(approved: true).count,
      referrals_made: user.referrals_made.count,
      total_earnings: user.balance + user.referral_balance,
      withdrawal_requests: user.withdrawals.count
    }
  end

  # Get financial analytics
  def financial_analytics
    {
      total_revenue: calculate_total_earnings,
      pending_payouts: Withdrawal.pending.sum(:amount),
      completed_payouts: Withdrawal.approved.sum(:amount),
      daily_earnings: Click.group("DATE(created_at)").sum(:earnings),
      monthly_earnings: Click.group("DATE_TRUNC('month', created_at)").sum(:earnings),
      withdrawal_stats: {
        total_requests: Withdrawal.count,
        pending: Withdrawal.pending.count,
        approved: Withdrawal.approved.count,
        rejected: Withdrawal.rejected.count
      }
    }
  end

  # Get task analytics
  def task_analytics
    total_tasks = Task.count
    completed_tasks = UserTask.where(approved: true).count
    task_completion_rate = total_tasks > 0 ? (completed_tasks.to_f / total_tasks * 100).round(2) : 0.0

    {
      total_tasks: total_tasks,
      completed_tasks: completed_tasks,
      pending_tasks: UserTask.where(approved: false).count,
      task_completion_rate: task_completion_rate,
      task_completions_by_day: UserTask.where(approved: true)
                                      .group("DATE(updated_at)")
                                      .count,
      task_types: Task.group(:task_type).count,
      top_performers: User.joins(:user_tasks)
                         .where(user_tasks: { approved: true })
                         .group('users.id')
                         .count
                         .sort_by { |_, count| -count }
                         .first(10)
                         .map { |user_id, count| [User.find(user_id), count] }
    }
  end

  # Get referral analytics
  def referral_analytics
    total_referrals = Referral.count
    active_referrals = Referral.joins(:referred_user).where(users: { suspended: false }).count
    referral_conversion_rate = User.count > 0 ? (active_referrals.to_f / User.count * 100).round(2) : 0.0

    {
      total_referrals: total_referrals,
      active_referrals: active_referrals,
      referral_conversion_rate: referral_conversion_rate,
      referral_earnings: Referral.sum(:reward_amount),
      referral_signups_by_day: Referral.group("DATE(created_at)").count,
      top_referrers: User.joins(:referrals_made)
                         .group('users.id')
                         .count
                         .sort_by { |_, count| -count }
                         .first(10)
                         .map { |user_id, count| [User.find(user_id), count] }
    }
  end
end