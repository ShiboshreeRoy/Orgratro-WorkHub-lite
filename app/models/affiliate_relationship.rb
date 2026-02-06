class AffiliateRelationship < ApplicationRecord
  belongs_to :user
  belongs_to :affiliate_program

  validates :user_id, uniqueness: { scope: :affiliate_program_id }
  validates :commission_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: %w[active inactive suspended] }

  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }
  scope :suspended, -> { where(status: 'suspended') }

  # Default status
  after_initialize :set_default_status, if: :new_record?

  private

  def set_default_status
    self.status ||= 'active'
  end
end