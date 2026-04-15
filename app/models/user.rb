class User < ApplicationRecord
  has_many :blogs, dependent: :nullify

  validates :username, presence: true
end
