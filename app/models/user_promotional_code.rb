class UserPromotionalCode < ApplicationRecord
  belongs_to :user
  belongs_to :promotional_code
end
