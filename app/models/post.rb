class Post < ApplicationRecord
    # 動画ファイルのバリデーションを一時的に無効化
    has_one_attached :video
    has_one_attached :thumbnail
    validates :title, presence: true
    validates :body, presence: true
    # validates :video, presence: true  # この行をコメントアウトして無効にする
  end