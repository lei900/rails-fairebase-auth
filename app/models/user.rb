class User < ApplicationRecord
  self.primary_key = :uid

  has_many :posts, primary_key: "uid", foreign_key: "user_uid"

  validates :uid, presence: true, uniqueness: true
end
