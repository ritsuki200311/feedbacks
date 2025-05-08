class CommentsController < ApplicationController
  before_action :authenticate_user!  # ログインしていないとコメントできないように
  before_action :set_post

  def create
    @comment = @post.comments.build(comment_params)
    @comment.user = current_user
    if @comment.save
      # 成功したら投稿詳細ページにリダイレクト
      redirect_to post_path(@post), notice: "コメントを投稿しました。"
    else
      # 失敗したら元の投稿一覧ページに戻すなど（適宜調整）
      redirect_to posts_path, alert: "コメントの投稿に失敗しました。"
    end
  end

  private

  def comment_params
    # 🔽 :parent_id を許可して、返信元のコメントIDを受け取るようにする
    params.require(:comment).permit(:body, :parent_id)
  end

  def set_post
    @post = Post.find(params[:post_id])
  end
end