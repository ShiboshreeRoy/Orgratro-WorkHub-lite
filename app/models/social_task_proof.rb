class SocialTaskProof < ApplicationRecord
  belongs_to :user
  belongs_to :social_task, foreign_key: :task_id, optional: true
  belongs_to :admin, class_name: "User", optional: true

  has_one_attached :proof_image

  enum status: { pending: 0, approved: 1, rejected: 2 }

  validates :post_url, presence: true,
                       format: URI::DEFAULT_PARSER.make_regexp(%w[http https])

  validate :proof_image_validation

  private

  def proof_image_validation
    return unless proof_image.attached?

    # Validate content type
    unless proof_image.content_type.in?(%w[image/jpeg image/jpg image/png image/gif])
      errors.add(:proof_image, "must be a valid image format (JPEG, PNG, GIF)")
    end

    # Validate file size
    if proof_image.byte_size > 5.megabytes
      errors.add(:proof_image, "image size must be less than 5MB")
    end
  end
end
