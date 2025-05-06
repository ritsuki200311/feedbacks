class UsersController < ApplicationController
  def index
    render plain: "Hello, world!"
  end
  def mypage
    @posts = current_user.posts.order(created_at: :desc) # 自分の投稿を新しい順に取得
    # @user = User.find(params[:id])
    # @posts = @user.posts
    # render :mypage
  end
end
