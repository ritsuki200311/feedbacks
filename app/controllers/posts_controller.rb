class PostsController < ApplicationController
  before_action :set_post, only: [:show, :edit, :update, :destroy]

  def destroy
    @post.destroy
    redirect_to posts_path, notice: '投稿が削除されました。'
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end
end