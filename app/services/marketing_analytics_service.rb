class MarketingAnalyticsService
  def initialize
    @date = Date.current
  end

  # Get comprehensive marketing analytics
  def marketing_dashboard_analytics
    {
      total_promotional_codes: PromotionalCode.count,
      active_promotional_codes: PromotionalCode.active.count,
      total_achievements: Achievement.count,
      unlocked_achievements: UserAchievement.where(unlocked: true).count,
      total_email_campaigns: EmailCampaign.count,
      active_email_campaigns: EmailCampaign.active.count,
      total_affiliate_programs: AffiliateProgram.count,
      active_affiliate_programs: AffiliateProgram.where(is_active: true).count,
      total_affiliates: AffiliateRelationship.count,
      active_affiliates: AffiliateRelationship.where(status: 'active').count,
      total_promo_code_usage: PromotionalCode.sum(:times_used),
      total_commissions_paid: AffiliateRelationship.sum(:commission_amount)
    }
  end

  # Get promotional code analytics
  def promotional_code_analytics(options = {})
    start_date = options[:start_date] || 30.days.ago.to_date
    end_date = options[:end_date] || Date.current

    codes = PromotionalCode.where(created_at: start_date..end_date.end_of_day)
    active_codes = codes.where(is_active: true)
    expired_codes = codes.where('expires_at < ?', Time.current)
    used_codes = codes.where('times_used > 0')

    {
      total_codes: codes.count,
      active_codes: active_codes.count,
      expired_codes: expired_codes.count,
      used_codes: used_codes.count,
      unused_codes: codes.count - used_codes.count,
      total_usage: codes.sum(:times_used),
      average_usage_per_code: codes.count > 0 ? (codes.sum(:times_used).to_f / codes.count).round(2) : 0,
      most_popular_code: find_most_popular_code(codes),
      usage_trend: calculate_usage_trend(start_date, end_date)
    }
  end

  # Get achievement analytics
  def achievement_analytics(options = {})
    start_date = options[:start_date] || 30.days.ago.to_date
    end_date = options[:end_date] || Date.current

    all_achievements = Achievement.where(created_at: start_date..end_date.end_of_day)
    unlocked_achievements = UserAchievement.where(
      created_at: start_date..end_date.end_of_day,
      unlocked: true
    )

    {
      total_achievements: all_achievements.count,
      unlocked_achievements: unlocked_achievements.count,
      locked_achievements: all_achievements.count - unlocked_achievements.count,
      achievement_completion_rate: calculate_achievement_completion_rate(all_achievements),
      top_achievements_by_points: Achievement.by_points(:desc).limit(5),
      achievement_types_distribution: calculate_achievement_type_distribution,
      total_points_awarded: calculate_total_points_awarded
    }
  end

  # Get email campaign analytics
  def email_campaign_analytics(options = {})
    start_date = options[:start_date] || 30.days.ago.to_date
    end_date = options[:end_date] || Date.current

    campaigns = EmailCampaign.where(created_at: start_date..end_date.end_of_day)
    sent_campaigns = campaigns.where(status: 'sent')
    scheduled_campaigns = campaigns.where(status: 'scheduled')
    failed_campaigns = campaigns.where(status: ['paused', 'cancelled'])

    {
      total_campaigns: campaigns.count,
      sent_campaigns: sent_campaigns.count,
      scheduled_campaigns: scheduled_campaigns.count,
      failed_campaigns: failed_campaigns.count,
      total_recipients: campaigns.sum(:recipients_count),
      total_opens: campaigns.sum(:opened_count),
      total_clicks: campaigns.sum(:clicked_count),
      average_open_rate: calculate_average_metric(campaigns, :open_rate),
      average_click_rate: calculate_average_metric(campaigns, :click_rate),
      top_performing_campaigns: EmailCampaign.top_performing(5),
      campaign_performance_trend: calculate_campaign_performance_trend(start_date, end_date)
    }
  end

  # Get affiliate program analytics
  def affiliate_program_analytics(options = {})
    start_date = options[:start_date] || 30.days.ago.to_date
    end_date = options[:end_date] || Date.current

    programs = AffiliateProgram.where(created_at: start_date..end_date.end_of_day)
    active_programs = programs.where(is_active: true)
    relationships = AffiliateRelationship.where(created_at: start_date..end_date.end_of_day)

    {
      total_programs: programs.count,
      active_programs: active_programs.count,
      total_affiliates: relationships.count,
      active_affiliates: relationships.where(status: 'active').count,
      total_commissions_paid: relationships.sum(:commission_amount),
      average_commission_per_affiliate: relationships.count > 0 ? (relationships.sum(:commission_amount).to_f / relationships.count).round(2) : 0,
      top_earning_affiliates: find_top_earning_affiliates(5),
      affiliate_enrollment_trend: calculate_affiliate_enrollment_trend(start_date, end_date),
      program_effectiveness: calculate_program_effectiveness
    }
  end

  # Calculate ROI for marketing efforts
  def calculate_marketing_roi
    # This would require more complex calculations involving costs vs returns
    # For now, we'll calculate a simplified version based on promotions vs earnings
    promotional_costs = calculate_promotional_costs
    referral_earnings = calculate_referral_earnings
    campaign_earnings = calculate_campaign_earnings

    roi = promotional_costs > 0 ? ((referral_earnings + campaign_earnings - promotional_costs) / promotional_costs * 100).round(2) : 0

    {
      promotional_costs: promotional_costs,
      referral_earnings: referral_earnings,
      campaign_earnings: campaign_earnings,
      roi_percentage: roi
    }
  end

  # Get user engagement metrics
  def user_engagement_metrics
    {
      total_users: User.count,
      active_users_last_7_days: calculate_active_users(7),
      active_users_last_30_days: calculate_active_users(30),
      user_retention_rate: calculate_user_retention_rate,
      average_session_duration: calculate_average_session_duration,
      most_active_users: find_most_active_users(10),
      user_growth_rate: calculate_user_growth_rate
    }
  end

  # Generate marketing report
  def generate_marketing_report(report_type, options = {})
    case report_type
    when 'promotional_codes'
      generate_promotional_codes_report(options)
    when 'achievements'
      generate_achievements_report(options)
    when 'email_campaigns'
      generate_email_campaigns_report(options)
    when 'affiliates'
      generate_affiliates_report(options)
    when 'engagement'
      generate_engagement_report(options)
    when 'comprehensive'
      generate_comprehensive_report(options)
    when 'revenue_impact'
      generate_revenue_impact_report(options)
    when 'roi_analysis'
      generate_roi_analysis_report(options)
    else
      raise ArgumentError, "Invalid report type: #{report_type}"
    end
  end

  # Track marketing attribution
  def track_marketing_attribution(user, source)
    # Log user acquisition source
    UserActivityLog.log_activity(
      user,
      'marketing_attribution',
      { source: source, timestamp: Time.current }
    )
  end

  # Get marketing funnel analytics
  def marketing_funnel_analytics
    {
      visitors: get_visitor_count,
      signups: User.count,
      activations: User.where('confirmed_at IS NOT NULL').count,
      first_transactions: get_first_transaction_count,
      recurring_users: get_recurring_user_count
    }
  end

  # Get seasonal marketing insights
  def seasonal_marketing_insights
    # Analyze patterns based on seasons/months
    {
      best_performing_months: calculate_best_performing_months,
      seasonal_trends: calculate_seasonal_trends,
      peak_engagement_periods: find_peak_engagement_periods
    }
  end

  private

  def find_most_popular_code(codes = nil)
    codes ||= PromotionalCode.all
    codes.order(times_used: :desc).first
  end

  def calculate_usage_trend(start_date, end_date)
    # Calculate daily usage over the period
    trend = {}
    (start_date..end_date).each do |date|
      daily_usage = PromotionalCode.where(
        'created_at >= ? AND created_at <= ?', 
        date.beginning_of_day, 
        date.end_of_day
      ).sum(:times_used)
      trend[date.strftime('%Y-%m-%d')] = daily_usage
    end
    trend
  end

  def calculate_achievement_completion_rate(achievements)
    total = achievements.count
    return 0 if total == 0

    unlocked = UserAchievement.where(
      achievement: achievements,
      unlocked: true
    ).count

    (unlocked.to_f / total * 100).round(2)
  end

  def calculate_achievement_type_distribution
    Achievement.group(:achievement_type).count
  end

  def calculate_total_points_awarded
    UserAchievement.joins(:achievement)
                   .where(unlocked: true)
                   .sum('achievements.points')
  end

  def calculate_average_metric(campaigns, metric)
    return 0 if campaigns.empty?

    values = campaigns.map { |campaign| campaign.send(metric) }
    (values.sum / values.size.to_f).round(2)
  end

  def calculate_campaign_performance_trend(start_date, end_date)
    # Calculate daily campaign performance over the period
    trend = {}
    (start_date..end_date).each do |date|
      daily_campaigns = EmailCampaign.where(
        'created_at >= ? AND created_at <= ?', 
        date.beginning_of_day, 
        date.end_of_day
      )
      
      avg_open_rate = calculate_average_metric(daily_campaigns, :open_rate)
      avg_click_rate = calculate_average_metric(daily_campaigns, :click_rate)
      
      trend[date.strftime('%Y-%m-%d')] = {
        open_rate: avg_open_rate,
        click_rate: avg_click_rate
      }
    end
    trend
  end

  def find_top_earning_affiliates(limit = 5)
    AffiliateRelationship.joins(:user)
                        .select('users.email, affiliate_relationships.commission_amount')
                        .order('affiliate_relationships.commission_amount DESC')
                        .limit(limit)
  end

  def calculate_affiliate_enrollment_trend(start_date, end_date)
    trend = {}
    (start_date..end_date).each do |date|
      daily_joins = AffiliateRelationship.where(
        'joined_at >= ? AND joined_at <= ?', 
        date.beginning_of_day, 
        date.end_of_day
      ).count
      trend[date.strftime('%Y-%m-%d')] = daily_joins
    end
    trend
  end

  def calculate_program_effectiveness
    programs = AffiliateProgram.includes(:affiliate_relationships)
    effectiveness = {}

    programs.each do |program|
      total_commission = program.affiliate_relationships.sum(:commission_amount)
      affiliate_count = program.affiliate_relationships.count
      effectiveness[program.name] = {
        total_commission: total_commission,
        affiliate_count: affiliate_count,
        avg_commission_per_affiliate: affiliate_count > 0 ? (total_commission / affiliate_count.to_f).round(2) : 0
      }
    end

    effectiveness
  end

  def calculate_promotional_costs
    # Estimate promotional costs based on discount values
    # This is a simplified calculation
    PromotionalCode.where('times_used > 0').sum(&:max_discount)
  end

  def calculate_referral_earnings
    # Calculate earnings from referral activities
    Referral.sum(:reward_amount)
  end

  def calculate_campaign_earnings
    # Calculate earnings from email-driven actions
    # This would require tracking specific conversions from emails
    0 # Placeholder - would need more complex tracking
  end

  def calculate_active_users(days = 7)
    User.where('last_active_at >= ?', days.days.ago).count
  end

  def calculate_user_retention_rate
    # Calculate based on users who return after first visit
    # This is a simplified version
    total_users = User.count
    return 0 if total_users == 0

    retained_users = User.where('created_at < ? AND last_active_at > ?', 7.days.ago, 1.day.ago).count
    (retained_users.to_f / total_users * 100).round(2)
  end

  def calculate_average_session_duration
    # This would require session tracking
    # Placeholder value
    0
  end

  def find_most_active_users(limit = 10)
    User.joins(:user_activity_logs)
        .group('users.id')
        .order('COUNT(user_activity_logs.id) DESC')
        .limit(limit)
  end

  def calculate_user_growth_rate
    # Calculate growth rate compared to previous period
    current_period_users = User.where('created_at >= ?', 30.days.ago).count
    previous_period_users = User.where('created_at >= ? AND created_at < ?', 60.days.ago, 30.days.ago).count

    return 0 if previous_period_users == 0
    ((current_period_users.to_f - previous_period_users) / previous_period_users * 100).round(2)
  end

  def get_first_transaction_count
    # Count users who made their first transaction
    # This would require transaction tracking
    0
  end

  def get_recurring_user_count
    # Count users who return regularly
    # This would require activity pattern analysis
    0
  end

  def get_visitor_count
    # This would come from traffic analytics
    # Placeholder value
    0
  end

  def calculate_best_performing_months
    # Analyze performance by month
    # Placeholder calculation
    {}
  end

  def calculate_seasonal_trends
    # Analyze seasonal patterns
    # Placeholder calculation
    {}
  end

  def find_peak_engagement_periods
    # Find periods with highest engagement
    # Placeholder calculation
    {}
  end

  def generate_promotional_codes_report(options)
    {
      title: "Promotional Codes Report",
      date_range: { start: options[:start_date], end: options[:end_date] },
      analytics: promotional_code_analytics(options),
      generated_at: Time.current
    }
  end

  def generate_achievements_report(options)
    {
      title: "Achievements Report",
      date_range: { start: options[:start_date], end: options[:end_date] },
      analytics: achievement_analytics(options),
      generated_at: Time.current
    }
  end

  def generate_email_campaigns_report(options)
    {
      title: "Email Campaigns Report",
      date_range: { start: options[:start_date], end: options[:end_date] },
      analytics: email_campaign_analytics(options),
      generated_at: Time.current
    }
  end

  def generate_affiliates_report(options)
    {
      title: "Affiliate Programs Report",
      date_range: { start: options[:start_date], end: options[:end_date] },
      analytics: affiliate_program_analytics(options),
      generated_at: Time.current
    }
  end

  def generate_comprehensive_report(options)
    {
      title: "Comprehensive Marketing Report",
      date_range: { start: options[:start_date], end: options[:end_date] },
      marketing_analytics: marketing_dashboard_analytics,
      promotional_analytics: promotional_code_analytics(options),
      achievement_analytics: achievement_analytics(options),
      email_campaign_analytics: email_campaign_analytics(options),
      affiliate_analytics: affiliate_program_analytics(options),
      roi_analysis: calculate_marketing_roi,
      user_engagement: user_engagement_metrics,
      generated_at: Time.current
    }
  end

  def generate_engagement_report(options)
    {
      title: "User Engagement Report",
      date_range: { start: options[:start_date], end: options[:end_date] },
      analytics: user_engagement_metrics,
      generated_at: Time.current
    }
  end

  def generate_revenue_impact_report(options)
    {
      title: "Revenue Impact Report",
      date_range: { start: options[:start_date], end: options[:end_date] },
      analytics: calculate_marketing_roi,
      generated_at: Time.current
    }
  end

  def generate_roi_analysis_report(options)
    {
      title: "ROI Analysis Report",
      date_range: { start: options[:start_date], end: options[:end_date] },
      analytics: calculate_marketing_roi,
      generated_at: Time.current
    }
  end
end