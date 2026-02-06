class AchievementCalculatorService
  def initialize(user)
    @user = user
  end

  # Check all possible achievements for the user and unlock any that are earned
  def check_and_unlock_achievements
    achievements_to_unlock = []

    Achievement.active.each do |achievement|
      next if achievement_already_unlocked?(achievement)

      if achievement_eligible?(achievement)
        achievements_to_unlock << achievement
      end
    end

    # Unlock all eligible achievements
    achievements_to_unlock.each do |achievement|
      unlock_achievement(achievement)
    end

    achievements_to_unlock
  end

  # Check if a specific achievement is eligible for the user
  def achievement_eligible?(achievement)
    case achievement.achievement_type
    when 'task_completion'
      check_task_completion_achievement(achievement)
    when 'referral'
      check_referral_achievement(achievement)
    when 'signup'
      check_signup_achievement(achievement)
    when 'milestone'
      check_milestone_achievement(achievement)
    when 'engagement'
      check_engagement_achievement(achievement)
    else
      false
    end
  end

  # Get all achievements for the user (unlocked and locked)
  def user_achievements_with_status
    all_achievements = Achievement.active
    user_unlocked_ids = @user.user_achievements.where(unlocked: true).pluck(:achievement_id)

    all_achievements.map do |achievement|
      {
        achievement: achievement,
        unlocked: user_unlocked_ids.include?(achievement.id),
        progress: calculate_progress(achievement)
      }
    end
  end

  # Get only unlocked achievements for the user
  def unlocked_achievements
    @user.user_achievements.includes(:achievement).where(unlocked: true)
  end

  # Get only locked achievements for the user
  def locked_achievements
    all_achievement_ids = Achievement.active.pluck(:id)
    unlocked_achievement_ids = @user.user_achievements.where(unlocked: true).pluck(:achievement_id)
    locked_ids = all_achievement_ids - unlocked_achievement_ids

    Achievement.where(id: locked_ids)
  end

  # Calculate progress toward a specific achievement
  def calculate_progress(achievement)
    case achievement.achievement_type
    when 'task_completion'
      calculate_task_completion_progress(achievement)
    when 'referral'
      calculate_referral_progress(achievement)
    when 'engagement'
      calculate_engagement_progress(achievement)
    else
      0
    end
  end

  # Award points for unlocked achievements
  def award_points_for_achievements
    unlocked_achievements.sum { |ua| ua.achievement.points }
  end

  # Get achievement statistics for the user
  def achievement_statistics
    {
      total_possible: Achievement.active.count,
      unlocked_count: unlocked_achievements.count,
      locked_count: locked_achievements.count,
      total_points: award_points_for_achievements,
      completion_percentage: calculate_completion_percentage
    }
  end

  # Trigger achievement check for specific event
  def trigger_event(event_type, data = {})
    case event_type
    when :task_completed
      handle_task_completion_event(data)
    when :referral_made
      handle_referral_event(data)
    when :login
      handle_login_event(data)
    when :withdrawal_made
      handle_withdrawal_event(data)
    when :link_clicked
      handle_link_click_event(data)
    end

    # Check for newly earned achievements after the event
    check_and_unlock_achievements
  end

  # Get achievements by type
  def achievements_by_type(type)
    user_achievements_with_status.select { |item| item[:achievement].achievement_type == type }
  end

  private

  def achievement_already_unlocked?(achievement)
    @user.user_achievements.exists?(achievement: achievement, unlocked: true)
  end

  def unlock_achievement(achievement)
    UserAchievement.find_or_create_by(
      user: @user,
      achievement: achievement
    ) do |user_achievement|
      user_achievement.unlocked = true
      user_achievement.earned_at = Time.current
    end

    # Award points to user
    @user.update(balance: @user.balance + achievement.points) if achievement.points.positive?

    # Log the achievement unlock
    Rails.logger.info "User #{@user.id} unlocked achievement: #{achievement.name}"

    # Create a notification for the user
    @user.notifications.create!(
      title: "Achievement Unlocked!",
      message: "Congratulations! You've unlocked the '#{achievement.name}' achievement and earned #{achievement.points} points!",
      notification_type: "achievement"
    )
  end

  def check_task_completion_achievement(achievement)
    case achievement.name
    when 'First Steps'
      @user.user_tasks.where(approved: true).count >= 1
    when 'Quick Learner'
      recent_tasks = @user.user_tasks
                    .where(approved: true)
                    .where('updated_at >= ?', 7.days.ago)
                    .count
      recent_tasks >= 10
    when 'Consistent Contributor'
      @user.user_tasks.where(approved: true).count >= 50
    else
      false
    end
  end

  def check_referral_achievement(achievement)
    case achievement.name
    when 'Social Butterfly'
      @user.referrals_made.count >= 5
    when 'Community Builder'
      successful_referrals = @user.referrals_made.joins(:referred_user)
                                            .where(users: { suspended: false })
                                            .count
      successful_referrals >= 20
    else
      false
    end
  end

  def check_signup_achievement(achievement)
    # Check for signup-based achievements
    case achievement.name
    when 'Early Bird'
      @user.created_at < 30.days.ago
    else
      false
    end
  end

  def check_milestone_achievement(achievement)
    case achievement.name
    when 'Power User'
      @user.subscription_plan&.name == 'VIP'
    else
      false
    end
  end

  def check_engagement_achievement(achievement)
    case achievement.name
    when 'Engagement Master'
      # Check for consecutive login days
      # This would require tracking login streaks separately
      # For now, we'll use a simplified approach
      @user.user_activity_logs.where(action: 'login').count >= 30
    else
      false
    end
  end

  def calculate_task_completion_progress(achievement)
    case achievement.name
    when 'First Steps'
      [@user.user_tasks.where(approved: true).count >= 1 ? 100 : 0, 100].min
    when 'Quick Learner'
      recent_tasks = @user.user_tasks
                    .where(approved: true)
                    .where('updated_at >= ?', 7.days.ago)
                    .count
      [(recent_tasks.to_f / 10.0 * 100).round, 100].min
    when 'Consistent Contributor'
      total_tasks = @user.user_tasks.where(approved: true).count
      [(total_tasks.to_f / 50.0 * 100).round, 100].min
    else
      0
    end
  end

  def calculate_referral_progress(achievement)
    case achievement.name
    when 'Social Butterfly'
      referrals_count = @user.referrals_made.count
      [(referrals_count.to_f / 5.0 * 100).round, 100].min
    when 'Community Builder'
      successful_referrals = @user.referrals_made.joins(:referred_user)
                                            .where(users: { suspended: false })
                                            .count
      [(successful_referrals.to_f / 20.0 * 100).round, 100].min
    else
      0
    end
  end

  def calculate_engagement_progress(achievement)
    case achievement.name
    when 'Engagement Master'
      login_count = @user.user_activity_logs.where(action: 'login').count
      [(login_count.to_f / 30.0 * 100).round, 100].min
    else
      0
    end
  end

  def calculate_completion_percentage
    total = Achievement.active.count
    unlocked = unlocked_achievements.count
    total.zero? ? 0 : ((unlocked.to_f / total) * 100).round(2)
  end

  def handle_task_completion_event(data)
    # Specific logic when a task is completed
    # Could include checking for task-completion achievements
  end

  def handle_referral_event(data)
    # Specific logic when a referral is made
    # Could include checking for referral achievements
  end

  def handle_login_event(data)
    # Specific logic when a user logs in
    # Could include checking for engagement achievements
  end

  def handle_withdrawal_event(data)
    # Specific logic when a withdrawal is made
  end

  def handle_link_click_event(data)
    # Specific logic when a link is clicked
  end
end