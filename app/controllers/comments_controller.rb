class CommentsController < ApplicationController
  before_action :authenticate_user!  # ログインしていないとコメントできないように
  before_action :set_post

  def index
    @comments = @post.comments.includes(:user).order(:created_at)

    respond_to do |format|
      format.json {
        render json: @comments.map { |comment|
          {
            id: comment.id,
            body: comment.body,
            x_position: comment.x_position,
            y_position: comment.y_position,
            user_name: comment.user&.name || "匿名",
            created_at: comment.created_at.strftime("%Y-%m-%d %H:%M")
          }
        }
      }
    end
  end

  def create
    @comment = @post.comments.build(comment_params)
    @comment.user = current_user

    respond_to do |format|
      if @comment.save
        CoinService.reward_for_comment(@comment)

        format.html { redirect_to post_path(@post), notice: "コメントを投稿しました。" }
        format.json {
          render json: {
            success: true,
            id: @comment.id,
            body: @comment.body,
            x_position: @comment.x_position,
            y_position: @comment.y_position,
            parent_id: @comment.parent_id,
            user_name: @comment.user&.name || "匿名",
            created_at: @comment.created_at.strftime("%Y-%m-%d %H:%M")
          }
        }
      else
        error_messages = @comment.errors.full_messages.join(", ")
        format.html { redirect_to post_path(@post), alert: "コメントの投稿に失敗しました: #{error_messages}" }
        format.json { render json: { success: false, errors: @comment.errors }, status: :unprocessable_entity }
      end
    end
  end

  private

  def comment_params
    # 🔽 :parent_id と位置情報を許可して、返信元のコメントIDと画像上の位置を受け取るようにする
    params.require(:comment).permit(:body, :parent_id, :x_position, :y_position, attachments: [])
  end

  def set_post
    @post = Post.find(params[:post_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "指定された投稿が見つかりませんでした。"
  end
end
