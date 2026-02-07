class UserTask < ApplicationRecord
  belongs_to :user
  belongs_to :task
  has_one_attached :image

  validates :proof, presence: true, on: :update, unless: :image_attached?
  validates :image, presence: true, on: :update, unless: :proof_present?

  scope :pending, -> { where(approved: false) }
  scope :approved, -> { where(approved: true) }

  def image_attached?
    image.attached?
  end

  def proof_present?
    proof.present?
  end

  def has_proof?
    proof.present? || image_attached?
  end

  def status
    if approved.nil?
      "pending"
    elsif approved
      "completed"
    else
      "rejected"
    end
  end

  def status_class
    case status
    when "completed"
      "bg-green-500/20 text-green-400"
    when "rejected"
      "bg-red-500/20 text-red-400"
    else
      "bg-yellow-500/20 text-yellow-400"
    end
  end
end
