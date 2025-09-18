class Comment < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :post

  has_many_attached :attachments

  has_many :votes, as: :votable, dependent: :destroy
  has_many :hearts, dependent: :destroy

  # 自己結合（コメントの返信用）
  belongs_to :parent, class_name: "Comment", optional: true

  has_many :replies, -> { order(created_at: :asc) },
         class_name: "Comment",
         foreign_key: :parent_id,
         dependent: :destroy

  after_create :increment_user_rank_points

  private

  def increment_user_rank_points
    post.user.increment!(:rank_points, 12) if post.user
  end
end
