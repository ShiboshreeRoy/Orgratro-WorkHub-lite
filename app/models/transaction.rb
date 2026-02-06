class Transaction < ApplicationRecord
  belongs_to :user

  validates :amount, presence: true, numericality: true
  validates :transaction_type, presence: true, inclusion: { in: %w[credit debit] }

  scope :credits, -> { where(transaction_type: 'credit') }
  scope :debits, -> { where(transaction_type: 'debit') }
  scope :ordered, -> { order(created_at: :desc) }
end