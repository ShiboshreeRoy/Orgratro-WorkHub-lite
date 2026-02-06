class Referral < ApplicationRecord
  belongs_to :referrer, class_name: "User"
  belongs_to :referred_user, class_name: "User", optional: true
  #belongs_to :user          # the newly referred user


  validates :token, presence: true, uniqueness: true

  before_validation :ensure_token, on: :create

  scope :unclaimed, -> { where(claimed: false) }

  # Marks the referral claimed and credits referrer
  def mark_claimed!(user:)
    return if claimed?

    transaction do
      update!(claimed: true, referred_user: user)
      referrer&.credit_referral(reward_amount)
    end
  end

  private

  def ensure_token
    return if token.present?

    loop do
      self.token = SecureRandom.urlsafe_base64(12)
      break unless self.class.exists?(token: token)
    end
  end
end
