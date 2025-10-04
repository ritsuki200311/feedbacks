class HeartsController < ApplicationController
  before_action :authenticate_user!

  def toggle
    comment = Comment.find(params[:comment_id])

    # 投稿者のみが他人のコメントにハートを付けられる
    unless current_user == comment.post.user && current_user != comment.user
      render json: { error: "Unauthorized" }, status: :forbidden
      return
    end

    heart = comment.hearts.find_by(user: current_user)
    existing_vote = comment.votes.find_by(user: current_user)
    vote_was_added = false
    vote_was_deleted = false

    if heart
      # ハートを削除
      heart.destroy
      hearted = false

      # ハート削除時に投票も一緒に削除
      if existing_vote
        existing_vote.destroy
        vote_was_deleted = true
      end
    else
      # ハートを追加
      comment.hearts.create!(user: current_user)
      hearted = true

      # ハート追加時に自動的にプラス投票も追加（まだ投票していない場合のみ）
      if existing_vote.nil?
        comment.votes.create!(user: current_user, value: 1)
        vote_was_added = true
      end
    end

    # 投票数を再計算
    up_count = comment.votes.where(value: 1).count
    down_count = comment.votes.where(value: -1).count
    user_vote = comment.votes.find_by(user: current_user)&.value || 0

    render json: {
      success: true,
      hearted: hearted,
      heart_count: comment.hearts.count,
      vote_updated: vote_was_added || vote_was_deleted, # 投票が追加または削除されたかどうか
      up_count: up_count,
      down_count: down_count,
      user_vote: user_vote
    }
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
