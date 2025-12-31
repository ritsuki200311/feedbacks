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
    Rails.logger.debug "=== POST CREATE DEBUG ==="
    Rails.logger.debug "All params: #{params.inspect}"
    Rails.logger.debug "post_params: #{post_params.inspect}"
    Rails.logger.debug "files in params[:post]: #{params[:post][:files].inspect if params[:post]}"
    Rails.logger.debug "=========================="

    # コイン数チェック（投稿には1枚必要）
    if current_user.coins < 1
      redirect_to new_post_path, alert: "コインが足りません。誰かの投稿にコメントしてコインを稼ぎましょう！"
      return
    end

    # 「送るユーザーを選ぶ」ボタンの場合は投稿を保存せず、データをセッションに保存
    if params[:commit] == "送るユーザーを選ぶ"
      # 投稿データをセッションに保存
      session[:pending_post_data] = {
        title: params[:post][:title],
        body: params[:post][:body],
        creation_type: params[:post][:creation_type],
        tag: params[:post][:tag]
      }

      # ファイルをActiveStorageにアップロードし、blob signed_idをセッションに保存
      if params[:post][:files].present?
        blob_signed_ids = []
        params[:post][:files].each do |file|
          next if file.blank?
          next unless file.respond_to?(:content_type) && file.respond_to?(:original_filename)

          # ActiveStorageにファイルをアップロード
          blob = ActiveStorage::Blob.create_and_upload!(
            io: file.open,
            filename: file.original_filename,
            content_type: file.content_type
          )

          # blob signed_idをセッションに保存
          blob_signed_ids << blob.signed_id
        end
        session[:pending_post_blob_ids] = blob_signed_ids if blob_signed_ids.any?
      end

      redirect_to select_recipient_collection_posts_path, notice: "投稿内容を保存しました。送信相手を選んでください。"
      return
    end

    @post = Post.new(post_params.except(:files))
    @post.user = current_user

    # 「投稿する」ボタンの場合
    @post.is_private = false  # 公開投稿として保存

    respond_to do |format|
      if @post.valid?
        begin
          @post.save
          Rails.logger.debug "Post saved successfully with ID: #{@post.id}"
        rescue => e
          Rails.logger.error "=== ERROR SAVING POST ==="
          Rails.logger.error "Error class: #{e.class}"
          Rails.logger.error "Error message: #{e.message}"
          Rails.logger.error "Backtrace: #{e.backtrace.first(10).join("\n")}"
          Rails.logger.error "=========================="
          format.html { redirect_to new_post_path, alert: "投稿の保存に失敗しました: #{e.message}" }
          return
        end

        # filesパラメータを適切なアタッチメントに振り分け（トランザクション外で実行）
        if params[:post] && params[:post][:files].present?
          begin
            Rails.logger.debug "Files parameter: #{params[:post][:files].inspect}"
            Rails.logger.debug "Files parameter class: #{params[:post][:files].class}"
            params[:post][:files].each_with_index do |file, index|
              Rails.logger.debug "File #{index}: #{file.inspect} (class: #{file.class})"
            end

            # バリデーションを回避するため、トランザクション外でアタッチメントを追加
            files_to_attach = params[:post][:files].reject(&:blank?)

            # 画像ファイル数制限チェック
            image_files = files_to_attach.select { |f| f.respond_to?(:content_type) && f.content_type&.start_with?('image/') }
            if image_files.count > 10
              @post.errors.add(:images, "は10枚まで添付できます")
              format.html { render :new, status: :unprocessable_entity }
              return
            end
            files_to_attach.each do |file|
              next unless file.respond_to?(:content_type) && file.respond_to?(:original_filename)

              Rails.logger.debug "Processing file: #{file.original_filename} (#{file.content_type})"

              case file.content_type
              when /^image\//
                @post.images.attach(file)
                Rails.logger.debug "Attached image: #{file.original_filename}"
              when /^video\//
                @post.videos.attach(file)
                Rails.logger.debug "Attached video: #{file.original_filename}"
              when /^audio\//
                @post.audios.attach(file)
                Rails.logger.debug "Attached audio: #{file.original_filename}"
              end
            end

            Rails.logger.debug "After attaching files: #{@post.images.count} images, #{@post.videos.count} videos, #{@post.audios.count} audios"
          rescue => e
            Rails.logger.error "=== ERROR ATTACHING FILES ==="
            Rails.logger.error "Error class: #{e.class}"
            Rails.logger.error "Error message: #{e.message}"
            Rails.logger.error "Backtrace: #{e.backtrace.first(10).join("\n")}"
            Rails.logger.error "=========================="
            @post.destroy
            format.html { redirect_to new_post_path, alert: "ファイルのアップロードに失敗しました: #{e.message}" }
            return
          end
        else
          Rails.logger.debug "No files parameter found or files parameter is empty"
        end

        # 成功時にセッションをクリア
        session[:submitted_files_info] = nil

        # コインを1枚消費
        current_user.update(coins: current_user.coins - 1)

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
    @vote_comments = @post.votes.includes(:user).where.not(comment: [ nil, "" ])
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

    respond_to do |format|
      format.html do
        # リファラーをチェックしてマイページから来た場合はマイページに戻る
        if request.referer&.include?("mypage")
          redirect_to mypage_path, notice: "投稿が削除されました。"
        else
          redirect_to root_path, notice: "投稿が削除されました。"
        end
      end
      format.turbo_stream do
        # Turbo Streamsでスムーズに削除
        render turbo_stream: turbo_stream.remove(@post)
      end
    end
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
        # 画像がある投稿のみをフィルタリング
        posts_with_images = @posts.select { |post| post.images.attached? }

        # 新しいサービス層を使用
        post_similarity_service = PostSimilarityService.new(current_user)

        # 階層的クラスタリングを生成
        hierarchical_clusters = post_similarity_service.generate_hierarchical_clusters(posts_with_images)

        # 従来の類似度マトリックス（後方互換性のため）
        similarity_matrix = post_similarity_service.calculate_similarity_matrix(posts_with_images)

        render json: {
          posts: posts_with_images.map do |post|
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
    # セッションに保存された投稿データがある場合はそれを使用
    if session[:pending_post_data].present?
      @post = Post.new(session[:pending_post_data])
      @post.user = current_user
      @is_pending = true
    else
      # 既存の投稿の場合
      @post = Post.find(params[:post_id])
      unless @post.user == current_user
        redirect_to root_path, alert: "権限がありません。"
        return
      end
      @is_pending = false
    end
  end

  def send_to_user
    # セッションから投稿データがある場合は、ここで投稿を作成
    if session[:pending_post_data].present?
      @post = Post.new(session[:pending_post_data])
      @post.user = current_user
      @post.is_private = true

      # バリデーションチェック
      unless @post.valid?
        redirect_to new_post_path, alert: "投稿内容にエラーがあります。"
        return
      end

      # 投稿を保存
      @post.save!

      # ファイルを添付（セッションから復元）
      if session[:pending_post_blob_ids].present?
        session[:pending_post_blob_ids].each do |signed_id|
          begin
            # signed_idからblobを取得
            blob = ActiveStorage::Blob.find_signed(signed_id)

            # content_typeに基づいて適切なアタッチメントに追加
            case blob.content_type
            when /^image\//
              @post.images.attach(blob)
            when /^video\//
              @post.videos.attach(blob)
            when /^audio\//
              @post.audios.attach(blob)
            end
          rescue ActiveSupport::MessageVerifier::InvalidSignature
            Rails.logger.error "Invalid blob signature: #{signed_id}"
          rescue ActiveRecord::RecordNotFound
            Rails.logger.error "Blob not found: #{signed_id}"
          end
        end
      end

      # セッションをクリア
      session.delete(:pending_post_data)
      session.delete(:pending_post_blob_ids)
    else
      # 既存の投稿の場合
      @post = Post.find(params[:post_id])
      unless @post.user == current_user
        redirect_to root_path, alert: "権限がありません。"
        return
      end
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
    if advisor_type == "creator"
      # クリエイター: 制作経験がある人（「経験なし」「していない」以外）
      users = users.where.not(supporter_profiles: { creation_experience: [ "経験なし", nil ] })
      users = users.where.not("supporter_profiles.support_genres @> ?", [ "していない" ].to_json)
    elsif advisor_type == "commenter"
      # コメンター: 制作経験がない、または少ない人
      users = users.where(supporter_profiles: { creation_experience: [ "経験なし", "1年未満", nil ] })
                   .or(users.where("supporter_profiles.support_genres @> ?", [ "していない" ].to_json))
    end

    # 対象ジャンルによる絞り込み
    if target_genres.present?
      if advisor_type == "creator"
        # クリエイター: support_genres（制作ジャンル）で絞り込み
        genre_conditions = target_genres.map { |genre| "supporter_profiles.support_genres @> ?" }
        users = users.where(genre_conditions.join(" OR "), *target_genres.map(&:to_json))
      elsif advisor_type == "commenter"
        # コメンター: interests（よく見るジャンル）で絞り込み
        genre_conditions = target_genres.map { |genre| "supporter_profiles.interests @> ?" }
        users = users.where(genre_conditions.join(" OR "), *target_genres.map(&:to_json))
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

    # ジャンルフィルタリング用のパラメータを取得
    @genre_filter = params[:genre_filter]
    Rails.logger.debug "Genre filter: '#{@genre_filter}'"

    if @genre_filter.present?
      # ジャンルが選択されている場合
      @results = User.joins(:supporter_profile).where(
        "supporter_profiles.support_genres::text ILIKE ?",
        "%#{@genre_filter}%"
      ).distinct.limit(20)
      Rails.logger.debug "Genre filter results: #{@results.map(&:name)}"
    elsif @query.present?
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
          "supporter_profiles.can_feedback ILIKE ? OR " \
          "supporter_profiles.interests::text ILIKE ? OR " \
          "supporter_profiles.support_genres::text ILIKE ? OR " \
          "supporter_profiles.support_styles::text ILIKE ? OR " \
          "supporter_profiles.personality_traits::text ILIKE ? OR " \
          "supporter_profiles.creation_experience ILIKE ? OR " \
          "supporter_profiles.age_group ILIKE ?",
          search_term, search_term, search_term, search_term, search_term, search_term, search_term, search_term, search_term
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
    score += 10 if [ "1-3年", "4-6年", "7-10年", "10年以上" ].include?(profile.creation_experience)
    score += 10 if profile.support_genres.length > 2
    score += 10 if profile.interests.length > 2
    score += rand(1..20) # ランダム要素
    [ score, 100 ].min # 最大100点
  end

  def generate_user_description_from_profile(profile)
    # プロフィール情報に基づいて説明文を生成する
    parts = []
    parts << "経験: #{profile.creation_experience}" if profile.creation_experience.present?
    parts << "創作: #{profile.support_genres.join(', ')}" if profile.support_genres.present?
    parts << "興味: #{profile.interests.join(', ')}" if profile.interests.present?
    parts.join(" / ")
  end

  def determine_advisor_type(profile)
    # プロフィールに基づいてアドバイザータイプを判定
    if profile.creation_experience.in?([ "経験なし", nil ]) ||
       profile.support_genres.include?("していない")
      "コメンター"
    else
      "クリエイター"
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
