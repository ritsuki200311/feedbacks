class User < ApplicationRecord
  # Deviseの認証モジュール
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # 投稿・コメント関連
  has_many :comments, dependent: :destroy
  has_many :posts
  has_many :votes, dependent: :destroy

  # DM機能に必要な関連
  has_many :entries
  has_many :rooms, through: :entries
  has_many :messages

  # 好み（Preference）の関連
  has_one :preference, dependent: :destroy

  has_one :supporter_profile, dependent: :destroy

  # コミュニティ関連
  has_many :community_users, dependent: :destroy
  has_many :communities, through: :community_users
  has_many :created_communities, class_name: 'Community', foreign_key: 'user_id', dependent: :destroy

  def rank
    if rank_points >= 40
      "A"
    elsif rank_points < 10
      "C"
    else
      "B"
    end
  end

  def add_coins(amount)
    self.coins += amount
    save
  end

  def remove_coins(amount)
    self.coins -= amount
    save
  end
end
