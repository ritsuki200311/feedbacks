class CommentsController < ApplicationController
    before_action :set_post
  
    def create
        @comment = @post.comments.build(comment_params)
        @comment.user = current_user  # ユーザーを設定
      
        if @comment.save
          redirect_to @post, notice: "コメントが投稿されました！"
        else
          redirect_to @post, alert: "コメントの投稿に失敗しました。"
        end
    end
  
    private
  
    def comment_params
      params.require(:comment).permit(:body)
    end
  
    def set_post
      @post = Post.find(params[:post_id])
    end
  end
  