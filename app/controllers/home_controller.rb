class HomeController < ApplicationController
  def index
    @posts = Post.all.order(created_at: :desc) # 投稿を新しい順に取得
  end
end