class PostsController < ApplicationController
  before_action :set_post, only: [ :show, :edit, :update, :destroy ]

  def new
    @post = Post.new
  end

  def create
    puts "DEBUG: AWS Access Key ID from credentials: #{Rails.application.credentials.dig(:aws, :access_key_id)}"
    @post = Post.new(post_params.except(:tag_list))
    @post.user = current_user
    @post.tag_list = post_params[:tag_list]

    respond_to do |format|
      if @post.valid? && CoinService.deduct_for_post(@post)
        @post.save
<<<<<<< Updated upstream

        format.html { redirect_to community_path(@post.community), notice: "投稿が作成されました。" }

        format.turbo_stream { flash.now[:notice] = "投稿が作成されました。" }
=======
        format.html { redirect_to root_path, notice: "投稿が作成されました。" }
        format.turbo_stream { redirect_to root_path, notice: "投稿が作成されました." }
>>>>>>> Stashed changes
      else
        Rails.logger.debug "Post save failed: #{@post.errors.full_messages.join(', ')}"
        flash[:alert] = @post.errors.empty? ? "コインが不足しているか、投稿に問題があります。" : @post.errors.full_messages.join(", ")
        format.html { redirect_to new_post_path, alert: flash[:alert] }
        format.turbo_stream { redirect_to new_post_path, alert: flash[:alert] }
      end
    end
  end


  def show
    @comment = @post.comments.build  # コメント投稿フォーム用
  end

  def edit
    # @post は before_action でセット済み
  end

  def update
    if @post.update(post_params)
      redirect_to @post, notice: "投稿が更新されました。"
    else
      render :edit
    end
  end

  def destroy
    @post.destroy
    redirect_to root_path, notice: "投稿が削除されました。"
  end



  private

  def post_params
    params.require(:post).permit(:title, :body, :creation_type, :request_tag, :tag_list, :community_id, images: [], videos: [], audios: [])
  end


  def set_post
    @post = Post.find(params[:id])
  end
end
