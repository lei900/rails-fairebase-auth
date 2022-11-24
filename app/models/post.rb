class Post < ApplicationRecord
  belongs_to :user, foreign_key: "user_uid"

  validates :title, presence: true
  validates :body, presence: true
end
