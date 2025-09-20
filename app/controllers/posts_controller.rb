class PostsController < ApplicationController
  include PostsHelper
  before_action :set_post, only: [ :show, :edit, :update, :destroy ]
  before_action :authenticate_user!, only: [ :new, :create, :destroy, :edit, :update, :select_recipient, :send_to_user ]
  before_action :authorize_post_owner, only: [ :edit, :update, :destroy ]

  def new
    @post = Post.new
    # セッションからファイル情報を復元
    @submitted_files_info = session[:submitted_files_info]
  end

  def create
    @post = Post.new(post_params.except(:files))
    @post.user = current_user

    # ボタンのcommitパラメータによって動作を変える
    if params[:commit] == "投稿する"
      @post.is_private = false  # 公開投稿として保存
    else
      @post.is_private = true  # 非公開投稿として保存
    end

    respond_to do |format|
      if @post.valid?
        @post.save

        # filesパラメータを適切なアタッチメントに振り分け
        if params[:post][:files].present?
          Rails.logger.debug "Files parameter: #{params[:post][:files].inspect}"
          Rails.logger.debug "Files parameter class: #{params[:post][:files].class}"
          params[:post][:files].each_with_index do |file, index|
            Rails.logger.debug "File #{index}: #{file.inspect} (class: #{file.class})"
          end
          attach_files_to_post(@post, params[:post][:files])
        end

        # 成功時にセッションをクリア
        session[:submitted_files_info] = nil

        if params[:commit] == "投稿する"
          format.html { redirect_to root_path, notice: "投稿を公開しました。" }
        else
          session[:pending_post_id] = @post.id
          format.html { redirect_to post_select_recipient_path(@post), notice: "投稿内容を保存しました。送信相手を選んでください。" }
        end
      else
        Rails.logger.debug "Post validation failed: #{@post.errors.full_messages.join(', ')}"
        # エラー時のファイル情報は保持しない（通常のプレビュー機能に任せる）
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
    
    # 投票コメントも取得
    @vote_comments = @post.votes.includes(:user).where.not(comment: [nil, ""])
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

  def map
    @posts = Post.includes(:user, :comments, images_attachments: :blob)
                 .order(created_at: :desc)
                 .limit(100)

    respond_to do |format|
      format.html
      format.json do
        # 新しいサービス層を使用
        post_similarity_service = PostSimilarityService.new(current_user)

        # 階層的クラスタリングを生成
        hierarchical_clusters = post_similarity_service.generate_hierarchical_clusters(@posts)

        # 従来の類似度マトリックス（後方互換性のため）
        similarity_matrix = post_similarity_service.calculate_similarity_matrix(@posts)

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
          end,
          # 階層的クラスタリング情報
          hierarchical_clusters: hierarchical_clusters,
          # 類似度マトリックス（後方互換性）
          similarity_matrix: similarity_matrix,
          # ユーザー行動データ
          current_user_behavior: current_user ? UserBehaviorService.new(current_user).get_behavior_profile : {}
        }
      end
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
      nil
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
    user_ids = selected_user_ids.split(",").map(&:strip).reject(&:blank?)
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

    # パラメータから絞り込み条件を取得
    advisor_type = params[:advisor_type]
    target_genres = params[:target_genres] || []
    age_group = params[:age_group]
    creation_experience = params[:creation_experience]
    support_genres = params[:support_genres] || []
    interests = params[:interests] || []

    # ユーザーを絞り込み
    users = User.joins(:supporter_profile).where.not(id: current_user.id)
    
    # アドバイザータイプによる絞り込み
    if advisor_type == 'creator'
      # クリエイター: 制作経験がある人（「経験なし」「していない」以外）
      users = users.where.not(supporter_profiles: { creation_experience: ['経験なし', nil] })
      users = users.where.not("supporter_profiles.support_genres @> ?", ['していない'].to_json)
    elsif advisor_type == 'commenter'
      # コメンター: 制作経験がない、または少ない人
      users = users.where(supporter_profiles: { creation_experience: ['経験なし', '1年未満', nil] })
                   .or(users.where("supporter_profiles.support_genres @> ?", ['していない'].to_json))
    end
    
    # 対象ジャンルによる絞り込み
    if target_genres.present?
      if advisor_type == 'creator'
        # クリエイター: support_genres（制作ジャンル）で絞り込み
        genre_conditions = target_genres.map { |genre| "supporter_profiles.support_genres @> ?" }
        users = users.where(genre_conditions.join(' OR '), *target_genres.map(&:to_json))
      elsif advisor_type == 'commenter'  
        # コメンター: interests（よく見るジャンル）で絞り込み
        genre_conditions = target_genres.map { |genre| "supporter_profiles.interests @> ?" }
        users = users.where(genre_conditions.join(' OR '), *target_genres.map(&:to_json))
      end
    end
    
    # 従来の絞り込み条件も適用
    users = users.where(supporter_profiles: { age_group: age_group }) if age_group.present?
    users = users.where(supporter_profiles: { creation_experience: creation_experience }) if creation_experience.present?
    
    if support_genres.present?
      users = users.where("supporter_profiles.support_genres @> ?", support_genres.to_json)
    end
    if interests.present?
      users = users.where("supporter_profiles.interests @> ?", interests.to_json)
    end

    # 上限を設定
    matched_users = users.limit(10)

    # 実際のマッチング結果を生成
    user_data = matched_users.map do |user|
      {
        id: user.id,
        name: user.name,
        description: generate_user_description_from_profile(user.supporter_profile),
        score: calculate_match_score_from_profile(user.supporter_profile),
        advisor_type: determine_advisor_type(user.supporter_profile)
      }
    end

    # スコア順でソート
    user_data = user_data.sort_by { |u| -u[:score] }.first(5)

    render json: { users: user_data }
  end

  private

  def attach_files_to_post(post, files)
    files.each do |file|
      # ファイルオブジェクトかどうかを確認
      next unless file.respond_to?(:content_type) && file.respond_to?(:original_filename)

      Rails.logger.debug "Attaching file: #{file.original_filename} (#{file.content_type})"

      case file.content_type
      when /^image\//
        post.images.attach(file)
      when /^video\//
        post.videos.attach(file)
      when /^audio\//
        post.audios.attach(file)
      else
        Rails.logger.warn "Unknown file type: #{file.content_type} for file #{file.original_filename}"
      end
    end
  end

  def extract_tags(tag_string)
    return [] if tag_string.blank?
    tag_string.split(",").map(&:strip).reject(&:blank?)
  end

  def analyze_comment_sentiments(comments)
    return {} if comments.empty?

    sentiment_words = {
      positive: [ "きれい", "美しい", "すてき", "素敵", "良い", "いい", "好き", "素晴らしい", "感動", "癒される" ],
      strong: [ "力強い", "迫力", "すごい", "凄い", "パワフル", "強烈", "インパクト", "圧倒" ],
      unique: [ "独特", "ユニーク", "面白い", "おもしろい", "個性的", "斬新", "新しい", "珍しい" ],
      gentle: [ "やさしい", "優しい", "ほっこり", "温かい", "あたたかい", "穏やか", "ソフト", "柔らか" ]
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
        # フリーワード検索 - ユーザー名とプロフィール内容を対象
        Rails.logger.debug "Free-word search: '%#{@query}%'"
        search_term = "%#{@query}%"
        
        # 統合クエリで検索
        @results = User.left_joins(:supporter_profile).where(
          "users.name ILIKE ? OR " \
          "supporter_profiles.favorite_artists ILIKE ? OR " \
          "supporter_profiles.interests::text ILIKE ? OR " \
          "supporter_profiles.support_genres::text ILIKE ? OR " \
          "supporter_profiles.support_styles::text ILIKE ? OR " \
          "supporter_profiles.personality_traits::text ILIKE ? OR " \
          "supporter_profiles.creation_experience ILIKE ? OR " \
          "supporter_profiles.age_group ILIKE ?",
          search_term, search_term, search_term, search_term, search_term, search_term, search_term, search_term
        ).distinct.limit(20)
        Rails.logger.debug "Free-word search results: #{@results.map(&:name)}"
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
    params.require(:post).permit(:title, :body, :creation_type, :community_id, images: [], videos: [], audios: [], files: [])
  end


  def set_post
    @post = Post.find(params[:id])
  end

  def authorize_post_owner
    return if @post&.user == current_user

    redirect_to root_path, alert: "権限がありません。" and return
  end

  def calculate_match_score_from_profile(profile)
    # プロフィール情報に基づいてスコアを計算する (簡易的な例)
    score = 50
    score += 10 if ['1-3年', '4-6年', '7-10年', '10年以上'].include?(profile.creation_experience)
    score += 10 if profile.support_genres.length > 2
    score += 10 if profile.interests.length > 2
    score += rand(1..20) # ランダム要素
    [score, 100].min # 最大100点
  end

  def generate_user_description_from_profile(profile)
    # プロフィール情報に基づいて説明文を生成する
    parts = []
    parts << "経験: #{profile.creation_experience}" if profile.creation_experience.present?
    parts << "創作: #{profile.support_genres.join(', ')}" if profile.support_genres.present?
    parts << "興味: #{profile.interests.join(', ')}" if profile.interests.present?
    parts.join(' / ')
  end

  def determine_advisor_type(profile)
    # プロフィールに基づいてアドバイザータイプを判定
    if profile.creation_experience.in?(['経験なし', nil]) || 
       profile.support_genres.include?('していない')
      'コメンター'
    else
      'クリエイター'
    end
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