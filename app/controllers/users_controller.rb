class UsersController < ApplicationController
  def index
    render plain: "Hello, world!"
  end
  def mypage
    @user = current_user
    @posts = current_user.posts.order(created_at: :desc) # 自分の投稿を新しい順に取得

    # @posts = @user.posts
    # render :mypage
  end

  def show
    @user = User.find(params[:id])
    @posts = @user.posts.order(created_at: :desc) # ユーザーの投稿を新しい順に取得
  end

end
