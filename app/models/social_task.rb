class SocialTask < ApplicationRecord
  has_many :social_task_proofs, foreign_key: :task_id, dependent: :destroy
  has_one_attached :campaign_image
  
  validates :name, presence: true, length: { minimum: 3, maximum: 100 }
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }
  validates :description, presence: true, length: { minimum: 10, maximum: 500 }
  
  # Optional image URL validation
  validates :image, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid image URL" }, allow_blank: true
  
  # Validate uploaded image file through Active Storage
  validate :campaign_image_validation
  
  # Scopes for common queries
  scope :active, -> { where(active: true) }
  scope :recent, -> { order(created_at: :desc) }
  
  # Helper method to get the image URL (either uploaded file or URL)
  def display_image_url
    if campaign_image.attached?
      Rails.application.routes.url_helpers.url_for(campaign_image)
    else
      image
    end
  end
  
  # Check if we have any image (uploaded or URL)
  def has_image?
    campaign_image.attached? || image.present?
  end
  
  private
  
  def campaign_image_validation
    return unless campaign_image.attached?
    
    # Validate content type
    unless campaign_image.content_type.in?(%w[image/jpeg image/jpg image/png image/gif])
      errors.add(:campaign_image, "must be a valid image format (JPEG, PNG, GIF)")
    end
    
    # Validate file size
    if campaign_image.byte_size > 5.megabytes
      errors.add(:campaign_image, "image size must be less than 5MB")
    end
  end
end
