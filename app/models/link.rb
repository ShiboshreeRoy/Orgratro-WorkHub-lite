class Link < ApplicationRecord
    belongs_to :user
    has_many :clicks, dependent: :destroy
    has_many :learn_and_earns, dependent: :destroy
    # has_many :file
    has_many_attached :files
    paginates_per 10  # Default items per page for pagination

    has_many :user_links, dependent: :nullify

    belongs_to :learn_and_earn, optional: true
    has_many :user_links
    has_many :viewed_by_users, through: :user_links, source: :user

    validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp, message: "must be a valid URL including http:// or https://" }, uniqueness: { case_sensitive: false }
    validates :title, presence: true, length: { minimum: 3, maximum: 255 }

    scope :active, -> { where(active: true) }
end
