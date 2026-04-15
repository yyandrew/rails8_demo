class User < ApplicationRecord
  has_many :blogs, dependent: :nullify

  has_secure_password

  validates :username, presence: true
  validates :username, uniqueness: true
end
