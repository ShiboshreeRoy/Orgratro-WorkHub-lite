class UserActivityLog < ApplicationRecord
  belongs_to :user
  
  validates :action, presence: true
  validates :timestamp, presence: true
  
  scope :recent, -> { order(timestamp: :desc) }
  scope :by_date, ->(date) { where("DATE(timestamp) = ?", date) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_action, ->(action) { where(action: action) }
  
  # Activity types
  ACTIVITY_TYPES = [
    'login',
    'logout',
    'task_completed',
    'task_submitted',
    'withdrawal_requested',
    'withdrawal_approved',
    'referral_signed_up',
    'link_clicked',
    'profile_updated',
    'notification_read',
    'contact_message_sent'
  ].freeze
  
  # Log user activity
  def self.log_activity(user, action, details = {})
    create!(
      user: user,
      action: action,
      details: details,
      timestamp: Time.current
    )
  end
  
  # Get user's recent activities
  def self.user_recent_activities(user, limit = 10)
    by_user(user.id).recent.limit(limit)
  end
  
  # Get activity counts by type for a user
  def self.user_activity_counts(user)
    by_user(user.id)
      .group(:action)
      .count
  end
  
  # Get daily activity count
  def self.daily_activity_count(date = Date.current)
    where("DATE(timestamp) = ?", date).count
  end
  
  # Get top active users in the last week
  def self.top_active_users(days = 7)
    where("timestamp >= ?", days.days.ago)
      .group(:user_id)
      .count
      .sort_by { |_, count| -count }
      .first(10)
  end
  
  # Get activity distribution by type
  def self.activity_distribution(start_date = 7.days.ago)
    where("timestamp >= ?", start_date)
      .group(:action)
      .count
  end
end