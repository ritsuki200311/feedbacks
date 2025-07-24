class Community < ApplicationRecord
  belongs_to :user
  has_many :community_users, dependent: :destroy
  has_many :users, through: :community_users
  has_many :posts, dependent: :destroy
end
