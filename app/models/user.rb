class User < ApplicationRecord
  # Deviseの認証モジュール
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # 投稿・コメント関連
  has_many :comments, dependent: :destroy
  has_many :posts

  # DM機能に必要な関連
  has_many :entries
  has_many :rooms, through: :entries
  has_many :messages

  # 好み（Preference）の関連
  has_one :preference, dependent: :destroy
end