class UserRelationshipsController < ApplicationController
  before_action :authenticate_user!

  def index
    # 現在のユーザーのプロフィール情報を取得
    current_profile = current_user.supporter_profile

    unless current_profile
      redirect_to new_supporter_profile_path, alert: "プロフィールを作成してからご利用ください。"
      return
    end

    # 他のユーザーのプロフィール情報を取得（プロフィールが存在するユーザーのみ）
    @users_with_profiles = User.joins(:supporter_profile)
                               .where.not(id: current_user.id)
                               .includes(:supporter_profile, :posts, :comments)

    # デバッグ情報をログに出力
    Rails.logger.info "Current user: #{current_user.name} (ID: #{current_user.id})"
    Rails.logger.info "Users with profiles count: #{@users_with_profiles.count}"
    Rails.logger.info "Current user profile attributes: #{current_profile.attributes}"
    @users_with_profiles.first(3).each do |user|
      Rails.logger.info "User: #{user.name} (ID: #{user.id}) - Profile attributes: #{user.supporter_profile.attributes}"
    end

    # 各ユーザーとの類似度を計算
    @user_similarities = calculate_user_similarities(current_profile, @users_with_profiles)

    # JSONデータとして渡す（ビューで使用）
    @users_data = @user_similarities.map do |user_data|
      user = user_data[:user]
      posts = user.posts.limit(3).order(created_at: :desc)
      comments = user.comments.limit(3).order(created_at: :desc).includes(:post)

      {
        id: user.id,
        name: user.name,
        similarity: user_data[:similarity],
        profile: user.supporter_profile.attributes.except("id", "user_id", "created_at", "updated_at"),
        posts_count: user.posts.count,
        comments_count: user.comments.count,
        recent_posts: posts.map { |post| {
          id: post.id,
          title: post.title,
          created_at: post.created_at,
          image_url: post.images.attached? ? Rails.application.routes.url_helpers.rails_blob_path(post.images.first, only_path: true) : nil
        } },
        recent_comments: comments.map { |comment| {
          id: comment.id,
          body: comment.body.truncate(50),
          post_title: comment.post.title,
          created_at: comment.created_at
        }}
      }
    end

    # 自分のデータも追加
    current_user_posts = current_user.posts.limit(3).order(created_at: :desc)
    current_user_comments = current_user.comments.limit(3).order(created_at: :desc).includes(:post)

    @current_user_data = {
      id: current_user.id,
      name: current_user.name,
      similarity: 1.0,
      profile: current_profile.attributes.except("id", "user_id", "created_at", "updated_at"),
      posts_count: current_user.posts.count,
      comments_count: current_user.comments.count,
      recent_posts: current_user_posts.map { |post| {
        id: post.id,
        title: post.title,
        created_at: post.created_at,
        image_url: post.images.attached? ? Rails.application.routes.url_helpers.rails_blob_path(post.images.first, only_path: true) : nil
      } },
      recent_comments: current_user_comments.map { |comment| {
        id: comment.id,
        body: comment.body.truncate(50),
        post_title: comment.post.title,
        created_at: comment.created_at
      }}
    }
  end

  private

  def calculate_user_similarities(current_profile, users)
    users.map do |user|
      other_profile = user.supporter_profile
      similarity = calculate_profile_similarity(current_profile, other_profile)

      {
        user: user,
        similarity: similarity
      }
    end.sort_by { |data| -data[:similarity] } # 類似度の高い順でソート
  end

  def calculate_profile_similarity(profile1, profile2)
    # 実際のプロフィール属性に基づく重み付け
    weights = {
      "interests" => 0.35,             # 趣味ジャンル（最重要）
      "support_genres" => 0.25,        # 支援ジャンル（重要）
      "personality_traits" => 0.15,    # 性格傾向
      "support_styles" => 0.10,        # 応援スタイル
      "age_group" => 0.08,             # 年齢層
      "standing" => 0.05,              # 立場
      "favorite_artists" => 0.02       # 好きな作品（参考程度）
    }

    total_similarity = 0.0
    total_weight = 0.0
    debug_info = {}

    weights.each do |attribute, weight|
      value1 = profile1[attribute]
      value2 = profile2[attribute]

      Rails.logger.info "Comparing #{attribute}: '#{value1}' vs '#{value2}'"

      if value1.present? && value2.present?
        # テキストの類似度を計算（簡易版：共通キーワードベース）
        similarity = calculate_text_similarity(value1, value2)
        debug_info[attribute] = {
          value1: value1,
          value2: value2,
          similarity: similarity,
          weight: weight,
          contribution: similarity * weight
        }
        total_similarity += similarity * weight
        total_weight += weight

        Rails.logger.info "  -> Similarity: #{similarity}, Weighted contribution: #{similarity * weight}"
      else
        Rails.logger.info "  -> Skipped (missing data)"
      end
    end

    final_similarity = total_weight > 0 ? total_similarity / total_weight : 0.0
    Rails.logger.info "Final similarity: #{final_similarity} (total: #{total_similarity}, weight: #{total_weight})"
    Rails.logger.info "Debug info: #{debug_info}"

    # 重み付けされた平均を計算
    final_similarity
  end

  def calculate_text_similarity(text1, text2)
    return 0.0 if text1.blank? || text2.blank?

    # テキストを正規化（配列の場合は文字列に変換）
    normalized_text1 = normalize_profile_text(text1)
    normalized_text2 = normalize_profile_text(text2)

    Rails.logger.info "    Normalized text1: '#{normalized_text1}'"
    Rails.logger.info "    Normalized text2: '#{normalized_text2}'"

    return 0.0 if normalized_text1.blank? || normalized_text2.blank?

    # テキストを単語に分割（日本語対応）
    words1 = extract_keywords(normalized_text1.downcase)
    words2 = extract_keywords(normalized_text2.downcase)

    Rails.logger.info "    Words1: #{words1}"
    Rails.logger.info "    Words2: #{words2}"

    return 0.0 if words1.empty? || words2.empty?

    # Jaccard係数で類似度を計算
    intersection = (words1 & words2).size
    union = (words1 | words2).size

    similarity = union > 0 ? intersection.to_f / union : 0.0
    Rails.logger.info "    Intersection: #{intersection}, Union: #{union}, Similarity: #{similarity}"

    similarity
  end

  def normalize_profile_text(text)
    case text
    when Array
      # 配列の場合は結合して文字列にする
      text.reject(&:blank?).join(", ")
    when String
      text
    when Hash
      # ハッシュの場合は値を結合
      text.values.reject(&:blank?).join(", ")
    else
      text.to_s
    end
  end

  def extract_keywords(text)
    return [] if text.blank?

    # 基本的なキーワード抽出（カンマ、スペース、改行で分割）
    keywords = text.split(/[,、\s\n]+/).map(&:strip).reject(&:empty?)

    # 実際のプロフィール内容に基づく用語統一（拡張版）
    normalized_keywords = keywords.map do |keyword|
      case keyword.downcase
      # 音楽関連の詳細分類
      when /^音楽$|^ミュージック$|^music$/
        "音楽"
      when /ライブ|コンサート|live|演奏会/
        "ライブ・コンサート"
      when /dtm|作曲|楽曲制作|音楽制作|楽曲/
        "DTM・作曲"
      when /バンド|バンド活動|演奏/
        "バンド活動"
      when /米津玄師|あいみょん|king gnu|ボカロ|ゲーム音楽/
        "現代ポップス系"
      when /bump|福山雅治|サカナクション/
        "ロック・ポップス系"
      when /髭男|ado|yoasobi/
        "新世代ポップス系"
      when /クラシック|古典音楽|オーケストラ/
        "クラシック音楽"

      # イラスト・漫画関連の詳細分類
      when /^イラスト$|^illustration$/
        "イラスト"
      when /^漫画$|^マンガ$|^manga$|^comic$/
        "漫画"
      when /デジタルアート|cg|デジタル/
        "デジタルアート"
      when /^アート$|美術|芸術|アナログ絵画/
        "アート・美術"
      when /同人誌|同人/
        "同人活動"
      when /鬼滅|呪術廻戦|spy|ワンピース|進撃|東京卍/
        "現代人気漫画"
      when /ジブリ|新海誠/
        "アニメーション映画"

      # 映像・映画・アニメ関連
      when /映像|動画|video|映像制作/
        "映像・動画"
      when /映画|movie|film|cinema/
        "映画"
      when /^アニメ$|^anime$|アニメーション/
        "アニメ"
      when /youtube|動画編集/
        "動画制作"
      when /marvel|ディズニー|洋画/
        "洋画・エンターテイメント"
      when /邦画|日本映画/
        "邦画"

      # 文章・文学関連
      when /^小説$|^novel$|文芸/
        "小説"
      when /文学|文章|文字|エッセイ/
        "文学・文章"
      when /ブログ|blog|web文章/
        "ブログ・エッセイ"
      when /東野圭吾|湊かなえ|村上春樹|又吉|朝井リョウ|森見登美彦/
        "現代文学作家"
      when /読書|書籍/
        "読書"

      # 複合・創作関連
      when /ゲーム|game|gaming/
        "ゲーム"
      when /mv|ミュージックビデオ|op|ed/
        "ミュージックビデオ"

      # 応援・支援スタイル
      when /金銭的支援|金銭的|お金|寄付|donation|支援/
        "金銭的支援"
      when /感想|コメント|comment|レビュー/
        "感想コメント"
      when /sns|シェア|拡散|宣伝|拡散・宣伝/
        "SNSシェア・拡散"
      when /コレクション|収集|作品をコレクション/
        "コレクション"

      # 性格・応援スタイル
      when /熱く|熱い|passionate|熱く語|熱く語りたい/
        "熱く語るタイプ"
      when /静か|じっくり|ゆっくり|静かに|じっくり鑑賞/
        "静かに鑑賞タイプ"

      # 年齢・立場
      when /^学生$|大学生|高校生/
        "学生"
      when /^社会人$|会社員|サラリーマン/
        "社会人"
      when /主婦|主夫/
        "主婦・主夫"

      # 年齢層
      when /19～22|19-22|19歳|20歳|21歳|22歳/
        "19～22歳"
      when /23～26|23-26|23歳|24歳|25歳|26歳/
        "23～26歳"
      when /27～30|27-30|27歳|28歳|29歳|30歳/
        "27～30歳"
      when /31～35|31-35|31歳|32歳|33歳|34歳|35歳/
        "31～35歳"

      # その他
      when /スポーツ|野球|サッカー|バスケ/
        "スポーツ"
      when /料理|グルメ|食べ物/
        "料理・グルメ"
      when /旅行|観光/
        "旅行"

      else
        keyword.downcase
      end
    end

    normalized_keywords.uniq
  end
end
