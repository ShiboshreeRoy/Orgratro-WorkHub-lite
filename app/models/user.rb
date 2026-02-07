class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

 # validates :name, presence: true
 # validates :wp_number, presence: true, format: { with: /\A\+?\d{10,15}\z/, message: "must be a valid phone number" }

 validates :email, presence: true, uniqueness: true
 validates :referral_code, presence: true, uniqueness: true



  enum role: { standard: 1, admin: 2, staff: 3, intern: 4 }

  has_many :clicks, dependent: :destroy
  has_many :links, dependent: :destroy
  has_many :withdrawals, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :learn_and_earns, dependent: :destroy
  has_many :contact_message, dependent: :destroy
  belongs_to :referred_by, class_name: "User", optional: true
  has_many :referrals_received, class_name: "User", foreign_key: :referred_by_id

  has_many :referrals_made, class_name: "Referral", foreign_key: :referrer_id, dependent: :destroy
  has_many :referrals_received, class_name: "Referral", foreign_key: :referred_user_id, dependent: :nullify

  before_validation :ensure_referral_code, on: :create

   validates :referral_code, presence: true, uniqueness: true




  # validates :proof, presence: true, on: :update  # proof required when user submits

  has_many :user_links, dependent: :destroy
  has_many :seen_links, through: :user_links, source: :link

  has_many :user_tasks, dependent: :destroy
  has_many :tasks, through: :user_tasks


  def total_earned
    # Calculate based on transaction records for accuracy
    transactions.credits.sum(:amount)
  end


  # Prevent login if suspended
  def active_for_authentication?
    super && !suspended?
  end

  has_many :social_task_proofs, dependent: :destroy
  has_many :transactions, dependent: :destroy
  has_many :user_achievements, dependent: :destroy
  has_many :achievements, through: :user_achievements
  has_many :user_activity_logs, dependent: :destroy
  has_many :user_promotional_codes, dependent: :destroy
  has_many :promotional_codes, through: :user_promotional_codes
  has_many :affiliate_relationships, dependent: :destroy
  has_many :affiliate_programs, through: :affiliate_relationships


  def social_tasks_completed_count
      social_task_proofs.approved.count
  end
  # Optional: custom message
  def inactive_message
    !suspended? ? super : :suspended
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "balance", "created_at", "email", "encrypted_password", "id", "id_value", "remember_created_at", "reset_password_sent_at", "reset_password_token", "role", "suspended", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "clicks", "contact_message", "learn_and_earns", "links", "notifications", "seen_links", "user_links", "withdrawals" ]
  end

  # Method to check if user completed any click/task
  def completed_task?
    clicks.exists?
  end

  # If you want to check specific link completion
  def completed_link?(link)
    clicks.exists?(link_id: link.id)
  end


  # Returns count of successful/claimed referrals
  def total_referrals
   referrals_made.where(claimed: true).count
  end


  # Safely increment referral balance with transaction recording
  def credit_referral(amount)
    amount = BigDecimal(amount.to_s)
    with_lock do
      self.class.where(id: id).update_all("referral_balance = COALESCE(referral_balance, 0) + #{amount}")
      # Create transaction record for referral bonus
      transactions.create!(
        amount: amount,
        transaction_type: "credit",
        description: "Referral bonus"
      )
      reload
    end
  end


  # Create or return a fresh referral token for sharing
  def create_referral_token!(invite_email: nil)
    referrals_made.create!(invite_email: invite_email)
  end

  # Get the last referral or create a new one
  def last_or_new_referral
    referrals_made.last || create_referral_token!
  end

  # Intern Dashboard Methods
  def can_access_dashboard?
    !is_intern || allow_dashboard_access || intern_graduated
  end

  def intern_progress_percentage
    return 100 if intern_graduated
    tasks_needed = required_tasks_for_graduation
    return 0 if tasks_needed.zero?
    ((intern_tasks_completed.to_f / tasks_needed) * 100).round(2)
  end

  def required_tasks_for_graduation
    case intern_level
    when 1 then 5   # Level 1: Complete 5 tasks
    when 2 then 10  # Level 2: Complete 10 tasks
    when 3 then 15  # Level 3: Complete 15 tasks
    else 20
    end
  end

  def check_and_update_level!
    return if intern_graduated

    if intern_tasks_completed >= required_tasks_for_graduation
      if intern_level >= 3
        # Graduate after completing level 3
        update(intern_graduated: true, is_intern: false)
      else
        # Level up
        update(intern_level: intern_level + 1)
      end
    end
  end

  def complete_intern_task!
    increment!(:intern_tasks_completed)
    check_and_update_level!
  end



private


   def ensure_referral_code
     self.referral_code ||= loop do
     token = SecureRandom.alphanumeric(8).upcase
     break token unless self.class.exists?(referral_code: token)
   end
  end
end
