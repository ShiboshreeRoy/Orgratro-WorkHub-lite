class SubscriptionPlan < ApplicationRecord
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :duration_days, presence: true, numericality: { greater_than: 0 }
  validates :description, presence: true

  has_many :user_subscriptions, dependent: :nullify
  has_many :users, through: :user_subscriptions

  # Standard plan features
  STANDARD_FEATURES = [
    'Basic task access',
    'Standard referral commission',
    'Email support'
  ].freeze

  # Premium plan features
  PREMIUM_FEATURES = [
    'All standard features',
    'Increased referral commission',
    'Priority task access',
    'Enhanced earning potential',
    'Priority customer support'
  ].freeze

  # VIP plan features
  VIP_FEATURES = [
    'All premium features',
    'Exclusive high-paying tasks',
    'VIP referral bonuses',
    'Dedicated account manager',
    '24/7 priority support'
  ].freeze

  # Get all available features for a plan
  def all_features
    features_array = []
    features_array.concat(eval(features)) if features.present?
    features_array
  end

  # Check if a plan includes a specific feature
  def includes_feature?(feature_name)
    all_features.include?(feature_name)
  end

  # Calculate discount percentage if applicable
  def discount_percentage(duration_months = 1)
    # Example: offer discount for longer subscriptions
    case duration_months
    when 3
      5  # 5% discount for 3-month subscription
    when 6
      10 # 10% discount for 6-month subscription
    when 12
      15 # 15% discount for annual subscription
    else
      0
    end
  end

  # Calculate discounted price based on duration
  def discounted_price(duration_months = 1)
    discount_pct = discount_percentage(duration_months)
    discounted_amount = price * (discount_pct / 100.0)
    price - discounted_amount
  end

  # Check if the plan is currently active
  def active?
    is_active
  end

  # Get plan by name
  def self.find_by_name(name)
    find_by(name: name)
  end

  # Get all active plans
  def self.active_plans
    where(is_active: true)
  end

  # Create standard subscription plans
  def self.create_default_plans
    [
      {
        name: 'Standard',
        description: 'Basic plan with standard features and earning potential',
        price: 0.0,  # Free tier
        features: STANDARD_FEATURES.to_json,
        duration_days: 30,
        is_active: true
      },
      {
        name: 'Premium',
        description: 'Premium features with enhanced earning potential',
        price: 9.99,
        features: PREMIUM_FEATURES.to_json,
        duration_days: 30,
        is_active: true
      },
      {
        name: 'VIP',
        description: 'VIP treatment with exclusive features and highest earning potential',
        price: 19.99,
        features: VIP_FEATURES.to_json,
        duration_days: 30,
        is_active: true
      }
    ].each do |plan_attrs|
      find_or_create_by(name: plan_attrs[:name]) do |plan|
        plan.attributes = plan_attrs
      end
    end
  end

  # Get all plan names
  def self.plan_names
    pluck(:name)
  end

  # Get plan by price range
  def self.by_price_range(min_price, max_price)
    where(price: min_price..max_price)
  end

  # Get most popular plan (based on number of subscribers)
  def self.most_popular
    joins(:user_subscriptions)
      .group('subscription_plans.id')
      .order('COUNT(user_subscriptions.id) DESC')
      .first
  end

  # Get plans sorted by price
  def self.sorted_by_price
    order(:price)
  end
end