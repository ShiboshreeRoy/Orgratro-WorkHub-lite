class SocialTaskProof < ApplicationRecord
  belongs_to :user
  belongs_to :social_task, foreign_key: :task_id
  belongs_to :admin, class_name: "User", optional: true 


  enum status: { pending: 0, approved: 1, rejected: 2 }

  validates :post_url, presence: true,
                       format: URI::DEFAULT_PARSER.make_regexp(%w[http https])
end
