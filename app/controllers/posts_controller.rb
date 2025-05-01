class PostsController < ApplicationController
  before_action :set_post, only: [:show, :edit, :update, :destroy]

  def new
    @post = Post.new
  end

  def create
    @comment = @post.comments.build(comment_params)
    @comment.user = current_user  # ユーザーを設定
  
    if @comment.save
      respond_to do |format|
        format.html { redirect_to @post, notice: "コメントが投稿されました！" }
        format.turbo_stream { render turbo_stream: turbo_stream.append("comments_for_post_#{@post.id}", partial: "comments/comment", locals: { comment: @comment }) }
      end
    else
      redirect_to @post, alert: "コメントの投稿に失敗しました。"
    end
  end 

  def edit
    # @post は :set_post コールバックでセットされます
  end

  def update
    if @post.update(post_params)
      redirect_to @post, notice: "投稿が更新されました。"
    else
      render :edit
    end
  end

  def show
    @comment = @post.comments.build  # 新しいコメントのインスタンスを作成
  end

  def destroy
    @post.destroy
    redirect_to posts_path, notice: "投稿が削除されました。"
  end

  private

  def post_params
    params.require(:post).permit(:title, :body, :thumbnail, :video)  # 必要なパラメータを許可
  end

  def set_post
    @post = Post.find(params[:id])
  end
end
