class PostsController < ApplicationController
    def new
      @post = Post.new
    end
  
    def create
      @post = Post.new(post_params)
      if @post.save
        redirect_to @post, notice: "投稿が完了しました！"
      else
        render :new
      end
    end
  
    private
  
    def post_params
      params.require(:post).permit(:title, :body)
    end
  end
  