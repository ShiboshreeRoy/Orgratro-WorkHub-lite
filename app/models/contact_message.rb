class ContactMessage < ApplicationRecord
  validates :name, :email, :subject, :message, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  belongs_to :user, optional: true

  # File attachments
  has_one_attached :project_image
  has_many_attached :project_files

  # Validations for file uploads
  validate :acceptable_image
  validate :acceptable_files

  private

  def acceptable_image
    return unless project_image.attached?

    unless project_image.byte_size <= 5.megabytes
      errors.add(:project_image, "is too big (max 5MB)")
    end

    acceptable_types = [ "image/jpeg", "image/png", "image/jpg", "image/gif", "image/webp" ]
    unless acceptable_types.include?(project_image.content_type)
      errors.add(:project_image, "must be a JPEG, PNG, GIF, or WebP")
    end
  end

  def acceptable_files
    return unless project_files.attached?

    project_files.each do |file|
      unless file.byte_size <= 10.megabytes
        errors.add(:project_files, "#{file.filename} is too big (max 10MB per file)")
      end

      acceptable_types = [
        "application/pdf",
        "application/msword",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "application/vnd.ms-excel",
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "application/zip",
        "application/x-rar-compressed",
        "text/plain"
      ]

      unless acceptable_types.include?(file.content_type)
        errors.add(:project_files, "#{file.filename} must be PDF, DOC, DOCX, XLS, XLSX, ZIP, RAR, or TXT")
      end
    end
  end
end
