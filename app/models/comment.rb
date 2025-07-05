class Comment < ApplicationRecord
  belongs_to :post
  belongs_to :user, optional: true

  # 自己結合（コメントの返信用）
  belongs_to :parent, class_name: "Comment", optional: true

  has_many :replies, -> { order(created_at: :asc) },
         class_name: "Comment",
         foreign_key: :parent_id,
         dependent: :destroy

  after_create :update_rank_points

  private

  def update_rank_points
    # コメントしたユーザーにポイントを加算
    user.increment!(:rank_points, 12) if user

    # コメントされた投稿の所有ユーザーにポイントを加算
    post.user.increment!(:rank_points, 12) if post.user
  end
end
