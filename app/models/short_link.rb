class ShortLink < ApplicationRecord
  before_create :generate_slug

  validates :original, presence: true

  def generate_slug
    self.slug = SecureRandom.urlsafe_base64(4) # short code
  end

  def short_url
    Rails.application.routes.url_helpers.short_redirect_url(slug: slug)
  end
end
