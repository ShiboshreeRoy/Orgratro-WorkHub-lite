class Notification < ApplicationRecord
  belongs_to :user, optional: true
  validates :title, :message, presence: true

  enum priority: { low: 0, medium: 1, high: 2, urgent: 3 }

  # Use constants instead of enum to avoid conflicts
  NOTIFICATION_TYPES = %w[system announcement update warning info].freeze

  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc) }
  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :for_user, ->(user) { where(user: user) }
  scope :global, -> { where(user_id: nil) }

  after_create :broadcast_notification

  def self.create_global(title, message, type: "announcement", priority: :medium, expires_in: nil)
    # Validate type
    type = type.to_s if type.is_a?(Symbol)
    unless NOTIFICATION_TYPES.include?(type)
      type = "info"
    end

    notification = create(
      title: title,
      message: message,
      notification_type: type,
      priority: priority,
      expires_at: expires_in ? Time.current + expires_in : nil,
      user_id: nil
    )

    # Broadcast to all connected users
    broadcast_notification(notification) if notification.persisted?
    notification
  end

  def mark_as_read!
    update(read: true, read_at: Time.current) unless read?
  end

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def urgency_class
    case priority
    when "urgent"
      "text-red-500 animate-pulse"
    when "high"
      "text-orange-500"
    when "medium"
      "text-yellow-500"
    else
      "text-blue-500"
    end
  end

  private

  def broadcast_notification
    # This will be handled by our Stimulus controller
    Rails.logger.info "Broadcasting notification: #{title}"
  end

  def self.broadcast_notification(notification)
    Rails.logger.info "Broadcasting global notification: #{notification.title}"
  end
end
