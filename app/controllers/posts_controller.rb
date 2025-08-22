class PostsController < ApplicationController
  include PostsHelper
  before_action :set_post, only: [ :show, :edit, :update, :destroy ]
  before_action :authenticate_user!, only: [ :new, :create, :destroy, :edit, :update ]
  before_action :authorize_post_owner, only: [ :edit, :update, :destroy ]

  def new
    @post = Post.new
  end

  def create
    @post = Post.new(post_params.except(:tag_list))
    @post.user = current_user
    @post.tag_list = post_params[:tag_list]

    respond_to do |format|
      # バリデーションチェック
      if @post.valid?
        # バリデーション成功後、コイン消費チェック
        if CoinService.deduct_for_post(@post)
          @post.save
          redirect_path = @post.community.present? ? community_path(@post.community) : root_path
          format.html { redirect_to redirect_path, notice: "投稿が作成されました。" }
          format.turbo_stream { flash.now[:notice] = "投稿が作成されました。" }
        else
          # コイン不足の場合、newページを再表示（リダイレクトしない）
          Rails.logger.debug "Coin deduction failed: #{@post.errors.full_messages.join(', ')}"
          format.html { render :new, status: :unprocessable_entity }
          format.turbo_stream { render :new, status: :unprocessable_entity }
        end
      else
        # バリデーション失敗の場合、newページを再表示
        Rails.logger.debug "Post validation failed: #{@post.errors.full_messages.join(', ')}"
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :new, status: :unprocessable_entity }
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

  def search
    @search_type = params[:search_type] || 'posts'
    @query = params[:query]&.strip
    
    case @search_type
    when 'users'
      search_users
    when 'posts'  
      search_posts
    when 'tags'
      search_tags
    else
      @search_type = 'posts'
      @results = []
    end
  end

  private

  def search_users
    if @query.present? && @query.match?(/\A\d+\z/)
      user = User.find_by(id: @query.to_i)
      @results = user ? [user] : []
    else
      @results = []
    end
  end

  def search_posts
    if @query.present?
      @results = Post.includes(:user, images_attachments: :blob)
                    .where("title ILIKE ? OR body ILIKE ?", "%#{@query}%", "%#{@query}%")
                    .order(created_at: :desc)
                    .limit(50)
    else
      @results = []
    end
  end

  def search_tags
    @creation_types = Post::CREATION_TYPES.keys
    @tag_options = tag_options
    @request_tags = request_tag_options
    
    if params[:creation_type].present? || params[:tag_list].present? || params[:request_tag].present?
      @results = Post.includes(:user, images_attachments: :blob)
      
      if params[:creation_type].present?
        creation_type_value = Post::CREATION_TYPES[params[:creation_type]]
        @results = @results.where(creation_type: creation_type_value) if creation_type_value
      end
      
      if params[:tag_list].present? && params[:tag_list].is_a?(Array)
        params[:tag_list].reject(&:blank?).each do |tag|
          @results = @results.where("tag ILIKE ?", "%#{tag}%")
        end
      end
      
      if params[:request_tag].present?
        @results = @results.where(request_tag: params[:request_tag])
      end
      
      @results = @results.order(created_at: :desc).limit(50)
    else
      @results = []
    end
  end

  private

  def post_params
    params.require(:post).permit(:title, :body, :creation_type, :request_tag, :tag_list, :community_id, images: [], videos: [], audios: [])
  end


  def set_post
    @post = Post.find(params[:id])
  end

  def authorize_post_owner
    return if @post&.user == current_user

    redirect_to root_path, alert: "権限がありません。" and return
  end
end
