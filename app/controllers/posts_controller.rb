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
      if @post.valid? && CoinService.deduct_for_post(@post)
        @post.save
        
        redirect_path = @post.community.present? ? community_path(@post.community) : root_path
        format.html { redirect_to redirect_path, notice: "投稿が作成されました。" }
        format.turbo_stream { flash.now[:notice] = "投稿が作成されました。" }
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

  def search
    @search_type = params[:search_type] || 'posts'
    @query = params[:query]&.strip
    @creation_type = params[:creation_type]
    @tag_list = params[:tag_list]
    @request_tag = params[:request_tag]
    
    Rails.logger.debug "=== SEARCH ACTION ==="
    Rails.logger.debug "Search type: #{@search_type}"
    Rails.logger.debug "Query: '#{@query}'"
    Rails.logger.debug "All params: #{params.inspect}"
    
    case @search_type
    when 'users'
      search_users
    when 'posts'  
      search_posts_and_tags
    else
      @search_type = 'posts'
      @results = []
    end
    
    Rails.logger.debug "Final results count: #{@results&.count}"
    Rails.logger.debug "===================="
    
    # デバッグビューがリクエストされた場合
    if request.path == '/search_debug'
      render :search_debug
    end
  end

  def search_simple
    @search_type = params[:search_type] || 'users'
    @query = params[:query]&.strip
    
    Rails.logger.debug "=== Search Simple Debug ==="
    Rails.logger.debug "Search type: #{@search_type}"
    Rails.logger.debug "Query: #{@query}"
    Rails.logger.debug "Params: #{params.inspect}"
    
    search_users
    
    Rails.logger.debug "Results count: #{@results&.count}"
    Rails.logger.debug "Results: #{@results&.map(&:name)}"
    Rails.logger.debug "=========================="
    
    render :search_simple
  end


  private

  def search_users
    Rails.logger.debug "=== search_users called ==="
    Rails.logger.debug "Query: '#{@query}'"
    Rails.logger.debug "Query present?: #{@query.present?}"
    
    if @query.present?
      if @query.match?(/\A\d+\z/)
        # 数字のみの場合はIDで検索
        Rails.logger.debug "Searching by ID: #{@query.to_i}"
        user = User.find_by(id: @query.to_i)
        @results = user ? [user] : []
        Rails.logger.debug "ID search result: #{user&.name || 'not found'}"
      else
        # 文字列の場合はユーザーネームで検索
        Rails.logger.debug "Searching by name: '%#{@query}%'"
        @results = User.where("name ILIKE ?", "%#{@query}%").limit(20)
        Rails.logger.debug "Name search results: #{@results.map(&:name)}"
      end
    else
      @results = []
    end
    
    Rails.logger.debug "Final results count: #{@results.count}"
    Rails.logger.debug "========================="
  end

  def search_posts_and_tags
    @creation_types = Post::CREATION_TYPES.keys
    @tag_options = tag_options
    @request_tags = request_tag_options
    
    @results = Post.includes(:user, images_attachments: :blob)
    
    # テキスト検索（タイトル・本文）
    if @query.present?
      @results = @results.where("title ILIKE ? OR body ILIKE ?", "%#{@query}%", "%#{@query}%")
    end
    
    # 作成タイプでフィルタ
    if @creation_type.present?
      creation_type_value = Post::CREATION_TYPES[@creation_type]
      @results = @results.where(creation_type: creation_type_value) if creation_type_value
    end
    
    # タグでフィルタ
    if @tag_list.present? && @tag_list.is_a?(Array)
      @tag_list.reject(&:blank?).each do |tag|
        @results = @results.where("tag ILIKE ?", "%#{tag}%")
      end
    end
    
    # リクエストタグでフィルタ
    if @request_tag.present?
      @results = @results.where(request_tag: @request_tag)
    end
    
    # 何も検索条件がない場合は空の結果
    if @query.blank? && @creation_type.blank? && (@tag_list.blank? || @tag_list.all?(&:blank?)) && @request_tag.blank?
      @results = []
    else
      @results = @results.order(created_at: :desc).limit(50)
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
