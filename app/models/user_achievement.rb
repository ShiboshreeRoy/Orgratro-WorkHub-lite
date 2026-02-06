class UserAchievement < ApplicationRecord
  belongs_to :user
  belongs_to :achievement
  
  validates :earned_at, presence: true, if: :unlocked?
  
  scope :unlocked, -> { where(unlocked: true) }
  scope :locked, -> { where(unlocked: false) }
end
