class HomeController < ApplicationController
  def index
    if params[:creation_type].present?
      @posts = Post.where(creation_type: params[:creation_type]).includes(:comments).order(created_at: :desc)
    else
      @posts = Post.includes(:comments).order(created_at: :desc)
    end
  end
end
