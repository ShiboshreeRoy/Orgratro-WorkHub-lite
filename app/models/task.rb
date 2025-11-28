class Task < ApplicationRecord
  belongs_to :user
  has_many :user_tasks, dependent: :destroy
  has_many :users, through: :user_tasks
  has_one_attached :image


  TASK_TYPES = [ "Click Link", "Social Media Post", "Follow & Subscribe", "Survey", "Other" ]
end
