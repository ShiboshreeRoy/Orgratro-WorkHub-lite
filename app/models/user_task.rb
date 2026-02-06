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
end
