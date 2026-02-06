class PromotionalCode < ApplicationRecord
  validates :code, presence: true, uniqueness: { case_sensitive: false }, format: { with: /\A[a-zA-Z0-9_]+\z/, message: "only allows letters, numbers, and underscores" }
  validates :description, presence: true
  validates :expires_at, presence: true
  validates :usage_limit, presence: true, numericality: { greater_than: 0 }
  validates :times_used, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :discount_percent, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, unless: :fixed_amount_only?
  validates :discount_fixed_amount, numericality: { greater_than_or_equal_to: 0 }, unless: :percent_only?

  has_many :user_promotional_codes, dependent: :destroy
  has_many :users, through: :user_promotional_codes

  before_validation :generate_code_if_blank, on: :create
  before_save :check_expiry_and_activation

  # Check if the promotional code is currently valid
  def valid_now?
    is_active? && 
    times_used < usage_limit && 
    expires_at.future?
  end

  # Check if the promotional code can be applied to an amount
  def applicable_to_amount?(amount)
    return false unless valid_now?
    
    # Additional checks can be added here based on minimum order amount, etc.
    true
  end

  # Calculate discount for a given amount
  def calculate_discount(amount)
    return 0 unless applicable_to_amount?(amount)
    
    percent_discount = 0
    fixed_discount = 0
    
    if discount_percent.present?
      percent_discount = amount * (discount_percent / 100.0)
    end
    
    if discount_fixed_amount.present?
      fixed_discount = discount_fixed_amount
    end
    
    # Return the sum of both discounts if both are present
    # Or whichever one is available
    [percent_discount, fixed_discount].sum
  end

  # Apply the promotional code and increment usage count
  def apply_to_user(user)
    return false unless valid_now?
    
    # Check if user has already used this code
    return false if user_promotional_codes.exists?(user: user)
    
    transaction do
      # Increment usage counter
      increment!(:times_used)
      
      # Create user promotional code record
      user_promotional_codes.create!(
        user: user,
        promotional_code: self
      )
    end
    
    true
  end

  # Get remaining usage count
  def remaining_uses
    usage_limit - times_used
  end

  # Check if code is expired
  def expired?
    expires_at.past?
  end

  # Check if code is at usage limit
  def usage_limit_reached?
    times_used >= usage_limit
  end

  # Check if code is fully used
  def fully_used?
    usage_limit_reached?
  end

  # Get formatted expiry date
  def formatted_expiry_date
    expires_at.strftime("%B %d, %Y at %I:%M %p")
  end

  # Get discount type (percentage, fixed, or combined)
  def discount_type
    if discount_percent.present? && discount_fixed_amount.present?
      'combined'
    elsif discount_percent.present?
      'percentage'
    elsif discount_fixed_amount.present?
      'fixed'
    else
      'none'
    end
  end

  # Get discount description
  def discount_description
    case discount_type
    when 'percentage'
      "#{discount_percent}% off"
    when 'fixed'
      "$#{discount_fixed_amount} off"
    when 'combined'
      "#{discount_percent}% + $#{discount_fixed_amount} off"
    else
      "No discount"
    end
  end

  # Get maximum possible discount for this code
  def max_discount(max_amount = nil)
    case discount_type
    when 'percentage'
      max_amount ? max_amount * (discount_percent / 100.0) : Float::INFINITY
    when 'fixed'
      discount_fixed_amount
    when 'combined'
      # Combined discount is additive
      max_amount ? (max_amount * (discount_percent / 100.0)) + discount_fixed_amount : Float::INFINITY
    else
      0
    end
  end

  # Create a promotional code with common presets
  def self.create_with_preset(preset_name, options = {})
    preset = PROMOTION_PRESETS[preset_name.to_sym]
    return nil unless preset

    attrs = preset.deep_merge(options.stringify_keys)
    create(attrs)
  end

  # Preset promotional codes
  PROMOTION_PRESETS = {
    welcome_bonus: {
      description: "Welcome bonus for new users",
      discount_percent: 10.0,
      usage_limit: 100,
      expires_at: 30.days.from_now,
      is_active: true
    },
    referral_discount: {
      description: "Special discount for referred users",
      discount_percent: 15.0,
      usage_limit: 50,
      expires_at: 14.days.from_now,
      is_active: true
    },
    seasonal_sale: {
      description: "Seasonal sale discount",
      discount_percent: 20.0,
      usage_limit: 200,
      expires_at: 7.days.from_now,
      is_active: true
    },
    loyalty_reward: {
      description: "Loyalty reward for returning customers",
      discount_fixed_amount: 5.0,
      usage_limit: 75,
      expires_at: 21.days.from_now,
      is_active: true
    },
    vip_exclusive: {
      description: "Exclusive VIP discount",
      discount_percent: 25.0,
      discount_fixed_amount: 10.0,
      usage_limit: 25,
      expires_at: 10.days.from_now,
      is_active: true
    }
  }.freeze

  # Get all active promotional codes
  def self.active
    where(is_active: true)
      .where('expires_at > ?', Time.current)
      .where('times_used < usage_limit')
  end

  # Get promotional codes by type (percentage, fixed, or combined)
  def self.by_discount_type(type)
    case type
    when 'percentage'
      where.not(discount_percent: nil).where(discount_fixed_amount: nil)
    when 'fixed'
      where(discount_percent: nil).where.not(discount_fixed_amount: nil)
    when 'combined'
      where.not(discount_percent: nil).where.not(discount_fixed_amount: nil)
    else
      all
    end
  end

  # Get expiring soon codes (within 7 days)
  def self.expiring_soon
    active.where('expires_at <= ?', 7.days.from_now)
  end

  # Bulk generate promotional codes
  def self.bulk_generate(count, base_attrs = {})
    codes = []
    count.times do
      attrs = base_attrs.dup
      attrs[:code] = generate_unique_code
      codes << create!(attrs)
    end
    codes
  end

  # Generate a unique promotional code
  def self.generate_unique_code(length = 8)
    loop do
      code = SecureRandom.alphanumeric(length).upcase
      break code unless exists?(code: code)
    end
  end

  private

  def generate_code_if_blank
    self.code = self.class.generate_unique_code if code.blank?
  end

  def check_expiry_and_activation
    # Auto-deactivate if expired
    self.is_active = false if expired?
  end

  def fixed_amount_only?
    discount_percent.blank?
  end

  def percent_only?
    discount_fixed_amount.blank?
  end
end