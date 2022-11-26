class User < ApplicationRecord
  has_many :posts

  validates :uid, presence: true, uniqueness: true
end
