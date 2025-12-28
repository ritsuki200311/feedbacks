class User < ApplicationRecord
  # Deviseの認証モジュール
  # 開発環境、または本番環境でSENDGRID_API_KEYが設定されている場合にメール確認を有効化
  # SENDGRID_API_KEYがない本番環境ではメール確認なしで登録可能
  if Rails.env.development? || (Rails.env.production? && ENV['SENDGRID_API_KEY'].present?)
    devise :database_authenticatable, :registerable,
           :recoverable, :rememberable, :validatable, :confirmable
  else
    devise :database_authenticatable, :registerable,
           :recoverable, :rememberable, :validatable
  end

  # バリデーション
  validates :name, presence: true, length: { minimum: 1, maximum: 50 }, uniqueness: true

  # 投稿・コメント関連
  has_many :comments, dependent: :destroy
  has_many :posts
  has_many :votes, dependent: :destroy
  has_many :post_recipients, dependent: :destroy
  has_many :received_posts, through: :post_recipients, source: :post

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
  has_many :created_communities, class_name: "Community", foreign_key: "user_id", dependent: :destroy

  # フォロー機能
  has_many :active_follows, class_name: "Follow", foreign_key: "follower_id", dependent: :destroy
  has_many :passive_follows, class_name: "Follow", foreign_key: "followed_id", dependent: :destroy
  has_many :following, through: :active_follows, source: :followed
  has_many :followers, through: :passive_follows, source: :follower

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
    return false unless amount.is_a?(Integer) && amount > 0
    return false if coins + amount > 999999 # 上限設定

    self.coins += amount
    save
  end

  def remove_coins(amount)
    return false unless amount.is_a?(Integer) && amount > 0
    return false if coins - amount < 0 # マイナス防止

    self.coins -= amount
    save
  end

  # フォロー関連のメソッド
  def following?(other_user)
    return false unless other_user
    begin
      following.include?(other_user)
    rescue ActiveRecord::StatementInvalid
      false
    end
  end

  def followers_count
    begin
      followers.count
    rescue ActiveRecord::StatementInvalid
      0
    end
  end

  def following_count
    begin
      following.count
    rescue ActiveRecord::StatementInvalid
      0
    end
  end

  # 未読メッセージ数を取得
  def unread_messages_count
    Message.joins(:room)
           .joins("JOIN entries ON entries.room_id = rooms.id")
           .where(entries: { user_id: id })
           .where.not(user_id: id)
           .where(is_read: false)
           .count
  end

  # バリデーション
  validates :name, presence: true, length: { maximum: 50 }
  validates :email, presence: true, length: { maximum: 254 }
  validates :trust_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }

  # 信用度スコア関連のメソッド
  def trust_score_stars
    trust_score.round(1)
  end

  def increment_trust_score(amount = 0.1)
    new_score = [trust_score + amount, 5.0].min
    update(trust_score: new_score)
  end

  def decrement_trust_score(amount = 0.05)
    new_score = [trust_score - amount, 0.0].max
    update(trust_score: new_score)
  end
end
