class PostsController < ApplicationController
  before_action :set_post, only: [:show, :edit, :update, :destroy]

  def new
    @post = Post.new
  end

  def create
    @post = Post.new(post_params)
    @post.user = current_user  # 投稿者のユーザー情報を設定（任意）

    if @post.save
      redirect_to @post, notice: "投稿が作成されました！"
    else
      render :new, alert: "投稿の作成に失敗しました。"
    end
  end

  def show
    @comment = @post.comments.build  # コメント投稿フォーム用
  end

  def edit
    # @post は before_action でセット済み
  end

  def update
    if @post.update(post_params)
      redirect_to @post, notice: "投稿が更新されました。"
    else
      render :edit
    end
  end

  def destroy
    @post.destroy
    redirect_to root_path, notice: "投稿が削除されました。"
  end

  def index
    @posts = Post.all.includes(:comments)  # コメントを含めて全投稿を取得
  end

  private

  def post_params
    params.require(:post).permit(:title, :body, :thumbnail, :video)
  end

  def set_post
    @post = Post.find(params[:id])
  end
end