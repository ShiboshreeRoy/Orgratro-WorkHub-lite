class InternTaskCompletion < ApplicationRecord
  belongs_to :user
  belongs_to :intern_task
  has_one_attached :proof_attachment

  # Validations
  validates :status, inclusion: { in: %w[pending submitted approved rejected] }, allow_blank: true
  validates :intern_task_id, presence: true
  validates :intern_task_id, uniqueness: { scope: :user_id, conditions: -> { where.not(status: "approved") }, message: "can't be resubmitted after approval" }
  validate :task_not_already_approved
  validate :intern_task_must_exist

  # Scopes
  scope :pending_approval, -> { where(status: "pending") }
  scope :approved, -> { where(status: "approved") }
  scope :submitted, -> { where(status: "submitted") }
  scope :by_recent, -> { order(created_at: :desc) }

  # Enums
  enum status: { pending: "pending", submitted: "submitted", approved: "approved", rejected: "rejected" }

  # Callbacks
  after_save :update_user_intern_progress

  private

  def task_not_already_approved
    if status == "submitted" && user.intern_task_completions.where(intern_task: intern_task, status: "approved").exists?
      errors.add(:intern_task_id, "has already been approved and cannot be resubmitted")
    end
  end

  def intern_task_must_exist
    if intern_task_id.present? && !InternTask.exists?(intern_task_id)
      errors.add(:intern_task_id, "must exist")
    end
  end

  def update_user_intern_progress
    # Only increment when approved
    if saved_change_to_status? && status == "approved"
      user.increment!(:intern_tasks_completed)
      user.check_and_update_level!
    end
  end
end
