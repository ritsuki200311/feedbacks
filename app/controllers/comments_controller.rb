class CommentsController < ApplicationController
  before_action :authenticate_user!  # ログインしていないとコメントできないように
  before_action :set_post

  def create
    @comment = @post.comments.build(comment_params)
    @comment.user = current_user
    if @comment.save

      if @post.user != current_user # 投稿者がコメントをした場合はコインを付与しない
        # コメント投稿者にコインを付与
        reward = Rails.application.config.x.coin.comment_reward
        current_user.update!(coins: current_user.coins + reward)
      end
      # 成功したら投稿詳細ページにリダイレクト
      redirect_to post_path(@post), notice: "コメントを投稿しました。"
    else
      error_messages = @comment.errors.full_messages.join(", ")
      redirect_to post_path(@post), alert: "コメントの投稿に失敗しました: #{error_messages}"
    end
  end

  private

  def comment_params
    # 🔽 :parent_id を許可して、返信元のコメントIDを受け取るようにする
    params.require(:comment).permit(:body, :parent_id)
  end

  def set_post
    @post = Post.find(params[:post_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "指定された投稿が見つかりませんでした。"
  end
end
