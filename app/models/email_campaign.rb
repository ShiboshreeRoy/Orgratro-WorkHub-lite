class EmailCampaign < ApplicationRecord
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :subject, presence: true
  validates :content, presence: true
  validates :sender_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :status, presence: true, inclusion: { in: %w[draft scheduled sending sent paused cancelled] }
  
  before_create :set_default_values
  before_save :update_recipients_count_if_needed

  # Status constants
  STATUS_DRAFT = 'draft'
  STATUS_SCHEDULED = 'scheduled'
  STATUS_SENDING = 'sending'
  STATUS_SENT = 'sent'
  STATUS_PAUSED = 'paused'
  STATUS_CANCELLED = 'cancelled'

  CAMPAIGN_STATUSES = [
    STATUS_DRAFT,
    STATUS_SCHEDULED,
    STATUS_SENDING,
    STATUS_SENT,
    STATUS_PAUSED,
    STATUS_CANCELLED
  ].freeze

  # Send the email campaign
  def send_campaign
    return false unless draft? || scheduled?

    update(status: 'sending')

    # In a real implementation, this would use a background job to send emails
    # For now, we'll simulate the process
    simulate_email_sending

    update(status: 'sent', sent_at: Time.current)
    true
  end

  # Schedule the email campaign for later
  def schedule_campaign(send_time)
    return false unless draft?

    update(
      status: 'scheduled',
      scheduled_at: send_time
    )
  end

  # Cancel a scheduled campaign
  def cancel_scheduled
    return false unless scheduled?

    update(status: 'cancelled')
  end

  # Pause a sending campaign
  def pause_sending
    return false unless sending?

    update(status: 'paused')
  end

  # Resume a paused campaign
  def resume_sending
    return false unless paused?

    update(status: 'sending')
  end

  # Check if campaign is ready to send
  def ready_to_send?
    scheduled? && (!scheduled_at? || scheduled_at.past?)
  end

  # Check campaign status
  def draft?
    status == 'draft'
  end

  def scheduled?
    status == 'scheduled'
  end

  def sending?
    status == 'sending'
  end

  def sent?
    status == 'sent'
  end

  def paused?
    status == 'paused'
  end

  def cancelled?
    status == 'cancelled'
  end

  # Calculate open rate
  def open_rate
    return 0 if recipients_count.to_i == 0
    (opened_count.to_f / recipients_count.to_i * 100).round(2)
  end

  # Calculate click rate
  def click_rate
    return 0 if recipients_count.to_i == 0
    (clicked_count.to_f / recipients_count.to_i * 100).round(2)
  end

  # Calculate bounce rate
  def bounce_rate
    return 0 if recipients_count.to_i == 0
    (bounce_count.to_f / recipients_count.to_i * 100).round(2)
  end

  # Get campaign statistics
  def statistics
    {
      recipients: recipients_count,
      opens: opened_count,
      clicks: clicked_count,
      bounces: bounce_count,
      open_rate: open_rate,
      click_rate: click_rate,
      bounce_rate: bounce_rate,
      delivered: recipients_count.to_i - bounce_count.to_i
    }
  end

  # Get engagement metrics
  def engagement_metrics
    {
      open_rate: open_rate,
      click_rate: click_rate,
      click_to_open_rate: opened_count.to_i > 0 ? ((clicked_count.to_f / opened_count.to_i) * 100).round(2) : 0,
      conversion_rate: 0.0  # Would need tracking for actual conversions
    }
  end

  # Get recipients for the campaign
  def get_recipients
    # This would typically return users based on targeting criteria
    # For now, we'll return all active users
    User.where(active: true)
  end

  # Update statistics after sending
  def update_statistics(opened_emails = 0, clicked_emails = 0, bounced_emails = 0)
    update(
      opened_count: opened_count.to_i + opened_emails,
      clicked_count: clicked_count.to_i + clicked_emails,
      bounce_count: bounce_count.to_i + bounced_emails
    )
  end

  # Duplicate campaign
  def duplicate(new_name = nil)
    new_campaign = dup
    new_campaign.name = new_name || "#{name} (Copy)"
    new_campaign.status = 'draft'
    new_campaign.sent_at = nil
    new_campaign.opened_count = 0
    new_campaign.clicked_count = 0
    new_campaign.bounce_count = 0
    new_campaign.recipients_count = 0
    new_campaign
  end

  # Get delivery timeline
  def delivery_timeline
    {
      created_at: created_at,
      scheduled_at: scheduled_at,
      sent_at: sent_at
    }
  end

  # Get campaigns by status
  def self.by_status(status)
    where(status: status)
  end

  # Get active campaigns (not cancelled or sent)
  def self.active
    where.not(status: ['cancelled', 'sent'])
  end

  # Get campaigns scheduled for immediate sending
  def self.ready_to_send
    where(status: 'scheduled')
      .where('scheduled_at IS NULL OR scheduled_at <= ?', Time.current)
  end

  # Get campaigns by date range
  def self.by_date_range(start_date, end_date)
    where(created_at: start_date..end_date)
  end

  # Get campaigns with high engagement (above average)
  def self.high_engagement_campaigns
    avg_open_rate = average(:open_rate).to_f
    joins('LEFT JOIN (SELECT email_campaign_id, COUNT(*) as open_count FROM email_opens GROUP BY email_campaign_id) eo ON email_campaigns.id = eo.email_campaign_id')
      .where('COALESCE(eo.open_count, 0) / NULLIF(email_campaigns.recipients_count, 0) * 100 > ?', avg_open_rate)
  end

  # Get top performing campaigns
  def self.top_performing(limit = 10)
    order(click_rate: :desc).limit(limit)
  end

  private

  def set_default_values
    self.status ||= 'draft'
    self.recipients_count ||= 0
    self.opened_count ||= 0
    self.clicked_count ||= 0
    self.bounce_count ||= 0
  end

  def update_recipients_count_if_needed
    if status_changed? && (status == 'sending' || status == 'sent') && recipients_count == 0
      self.recipients_count = get_recipients.count
    end
  end

  def simulate_email_sending
    # In a real implementation, this would connect to an email service
    # and actually send emails to recipients
    # For simulation, we'll just set some sample statistics
    
    recipients = get_recipients
    total_recipients = recipients.count
    
    # Simulate some engagement
    simulated_opens = (total_recipients * 0.25).to_i  # 25% open rate
    simulated_clicks = (simulated_opens * 0.10).to_i   # 10% click rate among opens
    simulated_bounces = (total_recipients * 0.02).to_i # 2% bounce rate
    
    update(
      recipients_count: total_recipients,
      opened_count: simulated_opens,
      clicked_count: simulated_clicks,
      bounce_count: simulated_bounces
    )
  end
end