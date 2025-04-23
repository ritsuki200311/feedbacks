class HomeController < ApplicationController
  def index
    @posts = Post.includes(:comments).order(created_at: :desc) # 投稿を新しい順に取得し、コメントも事前に読み込む
  end
end
