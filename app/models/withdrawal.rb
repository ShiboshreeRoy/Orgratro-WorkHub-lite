class Withdrawal < ApplicationRecord
  belongs_to :user

  # Scopes for different statuses
  scope :pending, -> { where(status: 'pending') }
  scope :approved, -> { where(status: 'approved') }
  scope :rejected, -> { where(status: 'rejected') }
  scope :processing, -> { where(status: 'processing') }

  validate :amount_within_balance
  validates :payment_method, presence: true
  #validates :amount, numericality: { greater_than_or_equal_to: 100.00 }
  #validates :status, inclusion: { in: %w[pending approved rejected] }

  def amount_within_balance
    if amount.present? && amount > user.balance
      errors.add(:amount, "cannot exceed your current balance ($#{user.balance})")
    end
  end
end