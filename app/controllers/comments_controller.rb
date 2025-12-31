class CommentsController < ApplicationController
  before_action :authenticate_user!, except: [:index]  # indexは認証不要（読み取り専用）
  before_action :set_post
  protect_from_forgery with: :null_session, only: [:create]

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
            image_index: comment.image_index,
            user_name: comment.user&.name || "匿名",
            created_at: comment.created_at.strftime("%Y-%m-%d %H:%M")
          }
        }
      }
    end
  end

  def create
    # セッションから手動でユーザーを取得
    unless user_signed_in?
      respond_to do |format|
        format.html { redirect_to new_user_session_path, alert: "コメントするにはログインまたは新規登録が必要です。" }
        format.json { render json: { success: false, error: "コメントするにはログインまたは新規登録が必要です" }, status: :unauthorized }
      end
      return
    end

    @comment = @post.comments.build(comment_params)
    @comment.user = current_user

    # image_indexがnilの場合、ピンコメントなら0に設定
    if @comment.x_position.present? && @comment.y_position.present? && @comment.image_index.nil?
      @comment.image_index = 0
    end

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
            image_index: @comment.image_index,
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
    params.require(:comment).permit(:body, :parent_id, :x_position, :y_position, :image_index, attachments: [])
  end

  def set_post
    @post = Post.find(params[:post_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "指定された投稿が見つかりませんでした。"
  end
end
