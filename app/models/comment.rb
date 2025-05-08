class Comment < ApplicationRecord
  belongs_to :post
  belongs_to :user, optional: true

  # 自己結合（コメントの返信用）
  belongs_to :parent, class_name: "Comment", optional: true

  has_many :replies, -> { order(created_at: :asc) }, 
         class_name: 'Comment', 
         foreign_key: :parent_id, 
         dependent: :destroy
end