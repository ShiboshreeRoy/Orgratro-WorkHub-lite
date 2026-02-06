class Achievement < ApplicationRecord
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :description, presence: true
  validates :points, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :achievement_type, presence: true, inclusion: { in: %w[task_completion referral signup milestone engagement] }

  has_many :user_achievements, dependent: :destroy
  has_many :users, through: :user_achievements

  # Default achievement types
  ACHIEVEMENT_TYPES = %w[task_completion referral signup milestone engagement].freeze

  # Default achievements
  DEFAULT_ACHIEVEMENTS = [
    {
      name: 'First Steps',
      description: 'Complete your first task',
      points: 10,
      achievement_type: 'task_completion',
      badge_image: 'first_steps_badge.png'
    },
    {
      name: 'Social Butterfly',
      description: 'Refer 5 friends to the platform',
      points: 50,
      achievement_type: 'referral',
      badge_image: 'social_butterfly_badge.png'
    },
    {
      name: 'Quick Learner',
      description: 'Complete 10 tasks in 7 days',
      points: 25,
      achievement_type: 'task_completion',
      badge_image: 'quick_learner_badge.png'
    },
    {
      name: 'Consistent Contributor',
      description: 'Complete 50 tasks',
      points: 100,
      achievement_type: 'task_completion',
      badge_image: 'consistent_contributor_badge.png'
    },
    {
      name: 'Top Performer',
      description: 'Be in the top 10% of earners this month',
      points: 200,
      achievement_type: 'milestone',
      badge_image: 'top_performer_badge.png'
    },
    {
      name: 'Engagement Master',
      description: 'Log in 30 days consecutively',
      points: 150,
      achievement_type: 'engagement',
      badge_image: 'engagement_master_badge.png'
    },
    {
      name: 'Community Builder',
      description: 'Successfully refer 20 users who complete their first task',
      points: 300,
      achievement_type: 'referral',
      badge_image: 'community_builder_badge.png'
    },
    {
      name: 'Power User',
      description: 'Reach VIP status',
      points: 500,
      achievement_type: 'milestone',
      badge_image: 'power_user_badge.png'
    }
  ].freeze

  # Check if an achievement is available to a user
  def available_to_user?(user)
    !user_achievements.exists?(user: user, unlocked: true)
  end

  # Calculate progress toward achievement (for progress-based achievements)
  def calculate_progress(user)
    case achievement_type
    when 'task_completion'
      calculate_task_completion_progress(user)
    when 'referral'
      calculate_referral_progress(user)
    when 'engagement'
      calculate_engagement_progress(user)
    when 'milestone'
      calculate_milestone_progress(user)
    else
      0
    end
  end

  # Get achievement by type
  def self.by_type(type)
    where(achievement_type: type)
  end

  # Get active achievements
  def self.active
    where(is_active: true)
  end

  # Get achievements ordered by points
  def self.by_points(order = :desc)
    order(points: order)
  end

  # Create default achievements
  def self.create_default_achievements
    DEFAULT_ACHIEVEMENTS.each do |achievement_attrs|
      find_or_create_by(name: achievement_attrs[:name]) do |achievement|
        achievement.attributes = achievement_attrs
      end
    end
  end

  # Get achievements for a specific user
  def self.for_user(user)
    joins(:user_achievements)
      .where(user_achievements: { user: user, unlocked: true })
      .distinct
  end

  # Get achievements by progress level
  def self.by_progress_threshold(min_progress = 0, max_progress = 100)
    # This would typically require joining with user achievements to calculate progress
    all
  end

  private

  def calculate_task_completion_progress(user)
    # For task completion achievements
    case name
    when 'First Steps'
      # Progress toward first task completion
      user.user_tasks.where(approved: true).count >= 1 ? 100 : 0
    when 'Quick Learner'
      # Progress toward 10 tasks in 7 days
      recent_tasks = user.user_tasks
                      .where(approved: true)
                      .where('updated_at >= ?', 7.days.ago)
                      .count
      [(recent_tasks.to_f / 10 * 100).round, 100].min
    when 'Consistent Contributor'
      # Progress toward 50 tasks
      total_tasks = user.user_tasks.where(approved: true).count
      [(total_tasks.to_f / 50 * 100).round, 100].min
    else
      0
    end
  end

  def calculate_referral_progress(user)
    # For referral achievements
    case name
    when 'Social Butterfly'
      # Progress toward 5 referrals
      referrals_count = user.referrals_made.count
      [(referrals_count.to_f / 5 * 100).round, 100].min
    when 'Community Builder'
      # Progress toward 20 successful referrals
      successful_referrals = user.referrals_made.joins(:referred_user)
                                             .where(users: { suspended: false })
                                             .count
      [(successful_referrals.to_f / 20 * 100).round, 100].min
    else
      0
    end
  end

  def calculate_engagement_progress(user)
    # For engagement achievements
    case name
    when 'Engagement Master'
      # Calculate consecutive login days
      # This is a simplified version - in reality, you'd need to track login streaks
      # For now, we'll estimate based on activity logs
      consecutive_days = user.user_activity_logs
                           .where(action: 'login')
                           .group('DATE(timestamp)')
                           .count
                           .keys
                           .map { |date_str| Date.parse(date_str) rescue nil }
                           .compact
                           .sort
      
      # Calculate consecutive days (simplified)
      # In a real app, you'd want to track this separately
      estimated_consecutive = consecutive_days.length > 1 ? 
        (consecutive_days.max - consecutive_days.min).to_i + 1 : 
        (consecutive_days.any? ? 1 : 0)
      
      [(estimated_consecutive.to_f / 30 * 100).round, 100].min
    else
      0
    end
  end

  def calculate_milestone_progress(user)
    # For milestone achievements
    case name
    when 'Top Performer'
      # This would require comparing user's earnings to others
      # Simplified version - would need more complex calculation in practice
      0  # Placeholder
    when 'Power User'
      # Check if user has VIP subscription
      user.subscription_plan&.name == 'VIP' ? 100 : 0
    else
      0
    end
  end
end