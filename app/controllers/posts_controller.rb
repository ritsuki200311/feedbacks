class PostsController < ApplicationController
  include PostsHelper
  before_action :set_post, only: [ :show, :edit, :update, :destroy ]
  before_action :authenticate_user!, only: [ :new, :create, :destroy, :edit, :update, :select_recipient, :send_to_user ]
  before_action :authorize_post_owner, only: [ :edit, :update, :destroy ]

  def new
    @post = Post.new
  end

  def create
    @post = Post.new(post_params)
    @post.user = current_user
    @post.is_private = true  # 最初は非公開投稿として保存

    respond_to do |format|
      if @post.valid?
        @post.save
        session[:pending_post_id] = @post.id
        format.html { redirect_to post_select_recipient_path(@post), notice: "投稿内容を保存しました。送信相手を選んでください。" }
      else
        Rails.logger.debug "Post validation failed: #{@post.errors.full_messages.join(', ')}"
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :new, status: :unprocessable_entity }
      end
    end
  end


  def show
    # 非公開投稿の場合、アクセス権限をチェック
    if @post.is_private?
      unless can_access_private_post?(@post)
        redirect_to root_path, alert: "この投稿にはアクセスできません。"
        return
      end
    end
    
    @comment = @post.comments.build  # コメント投稿フォーム用
    @is_private_view = @post.is_private?
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
    @search_type = params[:search_type] || "posts"
    @query = params[:query]&.strip
    @creation_type = params[:creation_type]
    @tag_list = params[:tag_list]
    @request_tag = params[:request_tag]

    Rails.logger.debug "=== SEARCH ACTION ==="
    Rails.logger.debug "Search type: #{@search_type}"
    Rails.logger.debug "Query: '#{@query}'"
    Rails.logger.debug "All params: #{params.inspect}"

    case @search_type
    when "users"
      search_users
    when "posts"
      search_posts_and_tags
    else
      @search_type = "posts"
      @results = []
    end

    Rails.logger.debug "Final results count: #{@results&.count}"
    Rails.logger.debug "===================="

    # デバッグビューがリクエストされた場合
    if request.path == "/search_debug"
      render :search_debug
    end
  end

  def search_simple
    @search_type = params[:search_type] || "users"
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

  def select_recipient
    @post = Post.find(params[:post_id])
    unless @post.user == current_user
      redirect_to root_path, alert: "権限がありません。"
      return
    end
    
  end

  def send_to_user
    @post = Post.find(params[:post_id])
    unless @post.user == current_user
      redirect_to root_path, alert: "権限がありません。"
      return
    end

    selected_user_ids = params[:selected_user_ids]
    if selected_user_ids.blank?
      redirect_to post_select_recipient_path(@post), alert: "送信先ユーザーを選択してください。"
      return
    end

    # カンマ区切りのIDを配列に変換
    user_ids = selected_user_ids.split(',').map(&:strip).reject(&:blank?)
    if user_ids.empty?
      redirect_to post_select_recipient_path(@post), alert: "送信先ユーザーを選択してください。"
      return
    end
    
    # 5人制限チェック
    if user_ids.length > 5
      redirect_to post_select_recipient_path(@post), alert: "送信相手は最大5人まで選択できます。"
      return
    end

    # フィードバック希望を投稿に保存
    feedback_requests = params[:feedback_requests]
    if feedback_requests.present?
      @post.update(feedback_requests: feedback_requests)
    end

    sent_users = []
    errors = []

    user_ids.each do |user_id|
      begin
        recipient = User.find(user_id)
        
        # PostRecipientレコードを作成して送信関係を記録
        PostRecipient.create!(
          post: @post,
          user: recipient,
          sent_at: Time.current
        )
        
        # DM room を作成または取得
        room = Room.find_existing_room_for_users(current_user, recipient)
        unless room
          room = Room.create!
          Entry.create!(user: current_user, room: room)
          Entry.create!(user: recipient, room: room)
        end

        # 投稿リンクをメッセージとして送信
        post_url = Rails.application.routes.url_helpers.post_url(@post, host: request.host_with_port)
        message_body = "新しい作品を共有します：#{@post.title}"
        
        Message.create!(
          user: current_user,
          room: room,
          body: message_body,
          post: @post,
          is_read: false
        )
        
        sent_users << recipient.name
      rescue ActiveRecord::RecordNotFound
        errors << "ユーザーID #{user_id} が見つかりません"
      rescue => e
        errors << "#{user_id} への送信でエラーが発生しました: #{e.message}"
      end
    end

    if sent_users.any?
      if errors.any?
        redirect_to rooms_path, notice: "#{sent_users.join('、')}さんに作品を送信しました。エラー: #{errors.join('、')}"
      else
        redirect_to rooms_path, notice: "#{sent_users.join('、')}さんに作品を送信しました。"
      end
    else
      redirect_to post_select_recipient_path(@post), alert: "送信に失敗しました: #{errors.join('、')}"
    end
  end

  def match_users
    @post = Post.find(params[:post_id])
    unless @post.user == current_user
      render json: { error: "権限がありません" }, status: :forbidden
      return
    end

    # パラメータからフィードバック希望を取得
    feedback_requests = params[:feedback_requests] || []

    # シンプルなマッチング実装
    matched_users = User.where.not(id: current_user.id).limit(5)
    
    # 実際のマッチング結果を生成（フィードバック希望に基づく）
    user_data = matched_users.map do |user|
      score = calculate_match_score_by_feedback(user, feedback_requests)
      {
        id: user.id,
        name: user.name,
        description: generate_user_description_by_feedback(user, feedback_requests),
        score: score
      }
    end

    # スコア順でソート
    user_data = user_data.sort_by { |u| -u[:score] }.first(3)

    render json: { users: user_data }
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
        @results = user ? [ user ] : []
        Rails.logger.debug "ID search result: #{user&.name || "not found"}"
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
    
    @results = Post.where(is_private: false).includes(:user, images_attachments: :blob)
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
    params.require(:post).permit(:title, :body, :community_id, images: [], videos: [], audios: [])
  end


  def set_post
    @post = Post.find(params[:id])
  end

  def authorize_post_owner
    return if @post&.user == current_user

    redirect_to root_path, alert: "権限がありません。" and return
  end

  def calculate_match_score(user, feedback_type, experience_level, field_preference)
    score = 50  # ベーススコア
    
    # ユーザーの投稿数に基づくスコア調整
    post_count = user.posts.count
    score += post_count * 2 if post_count > 0
    
    # ランダム要素を追加（実際の実装では別のロジックを使用）
    score += rand(1..30)
    
    score
  end

  def calculate_match_score_by_feedback(user, feedback_requests)
    score = 50  # ベーススコア
    
    # ユーザーの投稿数に基づくスコア調整
    post_count = user.posts.count
    score += post_count * 2 if post_count > 0
    
    # フィードバック希望に基づくスコア調整
    if feedback_requests.present?
      feedback_requests.each do |request|
        case request
        when "批評ください", "厳しい意見お待ちしています"
          score += 10 if post_count > 5  # 経験豊富なユーザーに高スコア
        when "優しい意見ください", "感想ください！"
          score += 8  # 全般的に適性あり
        when "困ってます！", "アドバイスください！"
          score += 12 if post_count > 3  # アドバイス経験者に高スコア
        end
      end
    end
    
    # ランダム要素を追加
    score += rand(1..20)
    
    score
  end

  def generate_user_description_by_feedback(user, feedback_requests)
    descriptions = []
    
    if feedback_requests.present?
      feedback_requests.each do |request|
        case request
        when "批評ください"
          descriptions << "作品の批評・分析が得意"
        when "優しい意見ください"
          descriptions << "優しく建設的なフィードバックが得意"
        when "厳しい意見お待ちしています"
          descriptions << "率直で具体的なアドバイスを提供"
        when "感想ください！"
          descriptions << "作品への感想・印象を丁寧に伝える"
        when "アドバイスください！"
          descriptions << "実践的なアドバイス・指導が得意"
        when "困ってます！"
          descriptions << "問題解決・サポートが得意"
        end
      end
    end
    
    post_count = user.posts.count
    if post_count > 10
      descriptions << "活発に投稿活動中（#{post_count}件の投稿）"
    elsif post_count > 0
      descriptions << "投稿経験あり（#{post_count}件）"
    else
      descriptions << "フィードバック専門ユーザー"
    end
    
    descriptions.uniq.join(" • ")
  end

  def generate_user_description(user, feedback_type, experience_level)
    descriptions = []
    
    case feedback_type
    when "技術的なアドバイス"
      descriptions << "技術的な観点からのアドバイスが得意"
    when "感情的な感想"
      descriptions << "作品の感情的な価値を理解するのが上手"
    when "改善提案"
      descriptions << "建設的な改善提案に定評"
    when "励ましのコメント"
      descriptions << "励ましとモチベーション向上が得意"
    end
    
    case experience_level
    when "初心者"
      descriptions << "初心者に優しいフィードバック"
    when "中級者"
      descriptions << "中級者レベルの適切なアドバイス"
    when "上級者"
      descriptions << "上級者向けの専門的な視点"
    when "プロフェッショナル"
      descriptions << "プロフェッショナルレベルの詳細な分析"
    end
    
    # ユーザーの投稿数情報も追加
    post_count = user.posts.count
    if post_count > 10
      descriptions << "活発な投稿者"
    elsif post_count > 5
      descriptions << "経験豊富"
    else
      descriptions << "新しいメンバー"
    end
    
    descriptions.join("、")
  end

  def can_access_private_post?(post)
    return false unless user_signed_in?
    
    # 投稿者本人は常にアクセス可能
    return true if post.user == current_user
    
    # PostRecipientテーブルで送信されたユーザーかチェック
    return true if post.post_recipients.exists?(user: current_user)
    
    # 後方互換性のため、古いメッセージベースのチェックも行う
    # この投稿を含むメッセージが送信されたルームに現在のユーザーが参加しているかチェック
    message_rooms = Room.joins(:messages, :entries)
                       .where(messages: { post_id: post.id })
                       .where(entries: { user_id: current_user.id })
                       .distinct
    
    message_rooms.exists?
  end

end
