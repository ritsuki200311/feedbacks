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
        format.html { redirect_to community_path(@post.community), notice: "投稿が作成されました。" }
        format.turbo_stream { flash.now[:notice] = "投稿が作成されました。" }
      else
        Rails.logger.debug "Post save failed: #{@post.errors.full_messages.join(', ')}"
        if @post.errors.empty?
          flash.now[:alert] = "コインが不足しているか、投稿に問題があります。"
        end
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("post_form", partial: "posts/form", locals: { post: @post }), status: :unprocessable_entity }
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

  def index
    @posts = Post.all.includes(:comments)  # コメントを含めて全投稿を取得
  end

  private

  def post_params
    params.require(:post).permit(:title, :body, :creation_type, :request_tag, :tag_list, :community_id, images: [], videos: [], audios: [])
  end


  def set_post
    @post = Post.find(params[:id])
  end
end
