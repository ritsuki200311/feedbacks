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

  # 高評価コメントを取得するスコープ
  scope :highly_rated, -> {
    joins(:votes)
      .select('comments.*, COUNT(votes.id) as vote_count, SUM(votes.value) as net_score')
      .group('comments.id')
      .having('SUM(votes.value) > 0') # ネットスコアがプラスのもの
      .order('SUM(votes.value) DESC, COUNT(votes.id) DESC, comments.created_at DESC')
  }

  scope :recent_highly_rated, -> (limit = 5) {
    where('comments.created_at >= ?', 7.days.ago)
      .joins(:votes)
      .select('comments.*, COUNT(votes.id) as vote_count, SUM(votes.value) as net_score')
      .group('comments.id')
      .having('SUM(votes.value) > 0')
      .order('SUM(votes.value) DESC, COUNT(votes.id) DESC, comments.created_at DESC')
      .limit(limit)
  }

  # 評価スコアを計算するメソッド
  def net_score
    votes.sum(:value)
  end

  def vote_count
    votes.count
  end

  private

  def increment_user_rank_points
    post.user.increment!(:rank_points, 12) if post.user
  end
end
