class InternTask < ApplicationRecord
  belongs_to :admin, class_name: "User", foreign_key: "admin_id"
  has_many :intern_task_completions, dependent: :destroy

  # File attachment
  has_one_attached :video_file

  # Validations
  validates :title, :description, :task_type, presence: true
  validates :status, inclusion: { in: %w[pending active completed archived] }, allow_blank: true
  validates :priority, inclusion: { in: 0..5 }, allow_nil: true

  # Scopes
  scope :active, -> { where(status: "active") }
  scope :by_priority, -> { order(priority: :desc) }

  # Enums
  enum task_type: { assignment: "assignment", tutorial: "tutorial", project: "project", quiz: "quiz", video_learning: "video_learning" }
  enum status: { pending: "pending", active: "active", completed: "completed", archived: "archived" }

  # Helper methods
  def youtube_embed_url
    return nil unless video_url.present?

    # Extract YouTube ID from various URL formats
    youtube_id = extract_youtube_id(video_url)
    youtube_id ? "https://www.youtube.com/embed/#{youtube_id}" : video_url
  end

  private

  def extract_youtube_id(url)
    # Match various YouTube URL formats
    regex_patterns = [
      /(?:youtube(?:-nocookie)?\.com\/([^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})/,
      /.*(?:youtu.be\/|v\/|e\/|u\/\w+\/|embed\/|v=)([^#\&\?]*).*/
    ]

    regex_patterns.each do |pattern|
      match = url.match(pattern)
      return match[1] if match && match[1] && match[1].length == 11
    end

    nil
  end
end
