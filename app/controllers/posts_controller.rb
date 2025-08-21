class PostsController < ApplicationController
  include PostsHelper
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

  def map
    @posts = Post.includes(:user, :comments, images_attachments: :blob)
                 .order(created_at: :desc)
                 .limit(100)

    respond_to do |format|
      format.html
      format.json do
        render json: {
          posts: @posts.map do |post|
            {
              id: post.id,
              title: post.title,
              body: post.body,
              user_name: post.user.name,
              user_id: post.user.id,
              is_current_user: (post.user == current_user),
              created_at: post.created_at,
              comments_count: post.comments.count,
              tags: extract_tags(post.tag),
              image_url: post.images.attached? ? url_for(post.images.first) : nil,
              comment_sentiments: analyze_comment_sentiments(post.comments)
            }
          end
        }
      end
    end
  end

  private

  def extract_tags(tag_string)
    return [] if tag_string.blank?
    tag_string.split(',').map(&:strip).reject(&:blank?)
  end

  def analyze_comment_sentiments(comments)
    return {} if comments.empty?
    
    sentiment_words = {
      positive: ['きれい', '美しい', 'すてき', '素敵', '良い', 'いい', '好き', '素晴らしい', '感動', '癒される'],
      strong: ['力強い', '迫力', 'すごい', '凄い', 'パワフル', '強烈', 'インパクト', '圧倒'],
      unique: ['独特', 'ユニーク', '面白い', 'おもしろい', '個性的', '斬新', '新しい', '珍しい'],
      gentle: ['やさしい', '優しい', 'ほっこり', '温かい', 'あたたかい', '穏やか', 'ソフト', '柔らか']
    }
    
    sentiment_counts = { positive: 0, strong: 0, unique: 0, gentle: 0 }
    
    comments.each do |comment|
      content = comment.body.to_s.downcase
      sentiment_words.each do |sentiment, words|
        words.each do |word|
          sentiment_counts[sentiment] += content.scan(word).length
        end
      end
    end
    
    sentiment_counts
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
end
