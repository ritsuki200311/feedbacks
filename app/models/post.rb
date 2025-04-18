# app/models/post.rb
class Post < ApplicationRecord
    has_one_attached :video # 動画ファイル
    has_one_attached :thumbnail # サムネイル画像
    validates :title, presence: true # タイトルが必須
    validates :video, presence: true # 動画ファイルが必須
end