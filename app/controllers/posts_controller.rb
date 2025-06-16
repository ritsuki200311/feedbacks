class PostsController < ApplicationController
  before_action :set_post, only: [:show, :edit, :update, :destroy]

  def new
    @post = Post.new
  end

  def create
    @post = Post.new(post_params.except(:tag_list)) # 仮想属性を除く
    @post.user = current_user
    @post.tag_list = post_params[:tag_list]         # 手動で代入

    cost = Rails.application.config.x.coin.post_cost
    if current_user.coins < cost
      redirect_to new_post_path, alert: "コインが不足しています。" and return
    end

    if @post.save
      current_user.decrement!(:coins, cost)  # コインを減らす
      redirect_to posts_path, notice: '投稿が作成されました。'
    else
      render :new
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
    params.require(:post).permit(:title, :body, :thumbnail, :video, tag_list: [])
  end
  

  def set_post
    @post = Post.find(params[:id])
  end
end