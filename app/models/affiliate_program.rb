class AffiliateProgram < ApplicationRecord
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :description, presence: true
  validates :commission_rate, presence: true, 
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :terms, presence: true

  has_many :affiliate_relationships, dependent: :destroy
  has_many :users, through: :affiliate_relationships

  # Default affiliate program types
  AFFILIATE_PROGRAM_TYPES = %w[standard premium enterprise].freeze

  # Status constants
  STATUS_ACTIVE = 'active'
  STATUS_INACTIVE = 'inactive'
  STATUS_SUSPENDED = 'suspended'

  PROGRAM_STATUSES = [
    STATUS_ACTIVE,
    STATUS_INACTIVE,
    STATUS_SUSPENDED
  ].freeze

  # Check if the affiliate program is currently active
  def active?
    is_active && status == 'active'
  end

  # Calculate commission for a given amount
  def calculate_commission(amount)
    return 0 unless active?

    amount * (commission_rate / 100.0)
  end

  # Get affiliates for this program
  def affiliates
    users.joins(:affiliate_relationships)
         .where(affiliate_relationships: { affiliate_program: self })
  end

  # Get active affiliates
  def active_affiliates
    affiliates.joins(:affiliate_relationships)
             .where(affiliate_relationships: { status: 'active' })
  end

  # Get affiliate count
  def affiliate_count
    affiliate_relationships.count
  end

  # Get active affiliate count
  def active_affiliate_count
    affiliate_relationships.where(status: 'active').count
  end

  # Calculate total commissions paid for this program
  def total_commissions_paid
    affiliate_relationships.sum(:commission_amount)
  end

  # Join the affiliate program
  def join_program(user)
    return false unless active?

    # Check if user is already a member
    return false if affiliate_relationships.exists?(user: user)

    AffiliateRelationship.create!(
      user: user,
      affiliate_program: self,
      commission_amount: 0,
      status: 'active',
      joined_at: Time.current
    )
  end

  # Leave the affiliate program
  def leave_program(user)
    relationship = affiliate_relationships.find_by(user: user)
    return false unless relationship

    relationship.update(status: 'inactive')
  end

  # Suspend an affiliate
  def suspend_affiliate(user)
    relationship = affiliate_relationships.find_by(user: user)
    return false unless relationship

    relationship.update(status: 'suspended')
  end

  # Reactivate an affiliate
  def reactivate_affiliate(user)
    relationship = affiliate_relationships.find_by(user: user)
    return false unless relationship

    relationship.update(status: 'active')
  end

  # Get affiliate relationship status
  def affiliate_status(user)
    relationship = affiliate_relationships.find_by(user: user)
    relationship&.status || 'not_member'
  end

  # Check if user is an active affiliate
  def active_affiliate?(user)
    affiliate_relationships.exists?(user: user, status: 'active')
  end

  # Get affiliate earnings by user
  def affiliate_earnings(user)
    relationship = affiliate_relationships.find_by(user: user)
    relationship&.commission_amount || 0
  end

  # Update affiliate earnings
  def update_affiliate_earnings(user, amount)
    relationship = affiliate_relationships.find_by(user: user)
    return false unless relationship

    relationship.update(commission_amount: relationship.commission_amount + amount)
  end

  # Get top affiliates by earnings
  def top_affiliates(limit = 10)
    users.joins(:affiliate_relationships)
         .where(affiliate_relationships: { affiliate_program: self })
         .order('affiliate_relationships.commission_amount DESC')
         .limit(limit)
  end

  # Get affiliate statistics
  def statistics
    {
      total_affiliates: affiliate_count,
      active_affiliates: active_affiliate_count,
      total_commissions_paid: total_commissions_paid,
      average_commission_per_affiliate: affiliate_count > 0 ? (total_commissions_paid / affiliate_count.to_f).round(2) : 0,
      commission_rate: commission_rate
    }
  end

  # Get affiliate performance metrics
  def performance_metrics
    stats = statistics
    {
      enrollment_rate: calculate_enrollment_rate,
      retention_rate: calculate_retention_rate,
      average_earnings_per_affiliate: stats[:average_commission_per_affiliate],
      commission_rate: stats[:commission_rate]
    }
  end

  # Get affiliates by join date range
  def affiliates_by_date_range(start_date, end_date)
    users.joins(:affiliate_relationships)
         .where(affiliate_relationships: { 
           affiliate_program: self, 
           joined_at: start_date..end_date 
         })
  end

  # Create a standard affiliate program
  def self.create_standard_program
    create!(
      name: 'Standard Affiliate Program',
      description: 'Join our standard affiliate program and earn commissions for every successful referral.',
      commission_rate: 10.0,
      terms: 'Affiliates must comply with our terms of service. Commissions are paid monthly.',
      is_active: true
    )
  end

  # Create a premium affiliate program
  def self.create_premium_program
    create!(
      name: 'Premium Affiliate Program',
      description: 'Our premium program offers higher commissions and exclusive benefits for top performers.',
      commission_rate: 15.0,
      terms: 'Premium affiliates must maintain a minimum performance threshold. Higher commissions apply.',
      is_active: true
    )
  end

  # Get all active programs
  def self.active_programs
    where(is_active: true)
  end

  # Get programs by commission rate range
  def self.by_commission_range(min_rate, max_rate)
    where(commission_rate: min_rate..max_rate)
  end

  # Get program with highest commission rate
  def self.highest_paying_program
    active_programs.order(commission_rate: :desc).first
  end

  # Get program with lowest commission rate
  def self.lowest_paying_program
    active_programs.order(commission_rate: :asc).first
  end

  # Search programs by name
  def self.search_by_name(query)
    where("LOWER(name) LIKE LOWER(?)", "%#{query}%")
  end

  # Get programs ordered by affiliate count
  def self.by_affiliate_count(order = :desc)
    joins('LEFT JOIN affiliate_relationships ON affiliate_programs.id = affiliate_relationships.affiliate_program_id')
      .group('affiliate_programs.id')
      .order("COUNT(affiliate_relationships.id) #{order}")
  end

  private

  def calculate_enrollment_rate
    # Calculate based on total users vs affiliates
    total_users = User.count
    return 0 if total_users == 0
    (affiliate_count.to_f / total_users * 100).round(2)
  end

  def calculate_retention_rate
    # Calculate based on active affiliates vs total affiliates
    return 0 if affiliate_count == 0
    (active_affiliate_count.to_f / affiliate_count * 100).round(2)
  end
end