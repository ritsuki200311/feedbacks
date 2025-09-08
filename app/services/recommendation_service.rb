# バズを避けた健全なレコメンドサービス
class RecommendationService
  def initialize(user = nil)
    @user = user
    @user_behavior_service = UserBehaviorService.new(user) if user
    @post_similarity_service = PostSimilarityService.new(user)
  end

  # ホームフィード用：バズを避けた穏やかなレコメンド
  def recommend_for_home_feed(posts, options = {})
    return posts.limit(20) if @user.nil?

    # 健全なSNS設計の設定
    config = {
      max_posts: options.fetch(:max_posts, 20),
      diversity_factor: options.fetch(:diversity_factor, 0.8),  # 80%は多様性重視
      avoid_viral_content: options.fetch(:avoid_viral_content, true),
      max_same_creator: options.fetch(:max_same_creator, 3),   # 同一作者最大3投稿
      quality_over_popularity: options.fetch(:quality_over_popularity, true)
    }

    scored_posts = calculate_gentle_recommendation_scores(posts, config)
    apply_healthy_feed_logic(scored_posts, config)
  end

  # 作品マップ用：類似度マトリックス
  def get_similarity_matrix(posts)
    @post_similarity_service.calculate_similarity_matrix(posts)
  end

  private

  def calculate_gentle_recommendation_scores(posts, config)
    posts.map do |post|
      score_breakdown = {}

      # 1. 個人の興味度 (50%) - メインの判定基準
      interest_score = @user_behavior_service&.calculate_interest_score(post) || 0.5
      score_breakdown[:interest] = interest_score

      # 2. コンテンツ品質 (25%) - エンゲージメント数ではなく質
      quality_score = calculate_content_quality(post)
      score_breakdown[:quality] = quality_score

      # 3. 時間的新鮮度 (15%) - 新しい作品も古い作品も適度に
      recency_score = calculate_gentle_recency_score(post)
      score_breakdown[:recency] = recency_score

      # 4. 多様性ボーナス (10%) - フィルターバブル回避
      diversity_score = calculate_diversity_bonus(post)
      score_breakdown[:diversity] = diversity_score

      # 総合スコア計算
      total_score = (interest_score * 0.5) +
                   (quality_score * 0.25) +
                   (recency_score * 0.15) +
                   (diversity_score * 0.1)

      # バイラルコンテンツの検出とペナルティ
      if config[:avoid_viral_content]
        viral_penalty = detect_viral_pattern(post)
        total_score *= (1.0 - viral_penalty)
        score_breakdown[:viral_penalty] = viral_penalty
      end

      {
        post: post,
        score: total_score.round(4),
        breakdown: score_breakdown
      }
    end
  end

  def calculate_content_quality(post)
    # バズ要素を排除した品質評価
    quality_factors = []

    # 1. タイトル・本文の充実度
    content_richness = calculate_content_richness(post)
    quality_factors << content_richness * 0.4

    # 2. 作者の実績（フォロワー数ではなく継続性）
    creator_consistency = calculate_creator_consistency(post.user)
    quality_factors << creator_consistency * 0.3

    # 3. コメントの質（数ではなく内容の丁寧さ）
    comment_quality = calculate_comment_thoughtfulness(post)
    quality_factors << comment_quality * 0.3

    quality_factors.sum
  end

  def calculate_gentle_recency_score(post)
    days_old = (Time.current - post.created_at) / 1.day

    case days_old
    when 0..1
      0.9  # 新しい投稿は高評価だがMAXにしない
    when 1..7
      0.8 - (days_old * 0.05)  # 1週間は緩やかに減衰
    when 7..30
      0.6 - ((days_old - 7) * 0.01)  # 1ヶ月まではそれなりの評価
    else
      [0.3, 0.4 - ((days_old - 30) * 0.005)].max  # 古い良作も発見される機会
    end
  end

  def calculate_diversity_bonus(post)
    # 最近推薦されたジャンルとの差別化
    # TODO: セッション内の推薦履歴を追跡
    rand(0.3..1.0)  # 暫定的にランダム要素で多様性を確保
  end

  def detect_viral_pattern(post)
    # 短期間での異常な拡散パターンを検出
    recent_hours = 6
    recent_engagement = post.votes.where('created_at > ?', recent_hours.hours.ago).count
    recent_comments = post.comments.where('created_at > ?', recent_hours.hours.ago).count

    # 6時間以内のエンゲージメント密度
    engagement_density = (recent_engagement + recent_comments * 1.5) / recent_hours

    # 密度が高すぎる場合はバイラル判定
    if engagement_density > 10
      penalty = [engagement_density / 50.0, 0.7].min
    else
      0.0
    end
  end

  def apply_healthy_feed_logic(scored_posts, config)
    # 1. 最低品質でフィルタ（とても緩い基準）
    qualified_posts = scored_posts.select { |item| item[:score] >= 0.2 }

    # 2. 同一作者の投稿数制限
    creator_limited = limit_posts_per_creator(qualified_posts, config[:max_same_creator])

    # 3. 多様性を重視したソート（完全スコア順ではない）
    diversified_posts = apply_diversity_sorting(creator_limited, config[:diversity_factor])

    # 4. 結果を投稿オブジェクトの配列に変換
    diversified_posts.first(config[:max_posts]).map { |item| item[:post] }
  end

  def limit_posts_per_creator(scored_posts, max_per_creator)
    creator_counts = Hash.new(0)
    
    # スコア順にソートしてから制限適用
    scored_posts.sort_by { |item| -item[:score] }.select do |item|
      creator_id = item[:post].user_id
      if creator_counts[creator_id] < max_per_creator
        creator_counts[creator_id] += 1
        true
      else
        false
      end
    end
  end

  def apply_diversity_sorting(posts, diversity_factor)
    # diversity_factor: 0.0 = 完全スコア順, 1.0 = 完全ランダム
    posts.sort_by do |item|
      score_component = item[:score] * (1.0 - diversity_factor)
      random_component = rand * diversity_factor
      -(score_component + random_component)
    end
  end

  # 品質評価のヘルパーメソッド
  def calculate_content_richness(post)
    # タイトル・本文の充実度
    title_length = post.title&.length || 0
    body_length = post.body&.length || 0
    
    # 適度な長さを評価（長すぎても良くない）
    title_score = title_length > 5 ? [1.0, title_length / 30.0].min : 0.3
    body_score = body_length > 10 ? [1.0, body_length / 200.0].min : 0.5
    
    (title_score + body_score) / 2.0
  end

  def calculate_creator_consistency(user)
    # 作者の継続性（投稿頻度の一貫性）
    recent_posts = user.posts.where('created_at > ?', 30.days.ago)
    total_posts = user.posts.count

    if total_posts >= 5 && recent_posts.count >= 1
      [1.0, Math.log(total_posts) * 0.2].min
    else
      0.4  # 新規ユーザーに対する基本スコア
    end
  end

  def calculate_comment_thoughtfulness(post)
    comments = post.comments.limit(20)
    return 0.5 if comments.empty?

    thoughtful_comments = comments.select { |c| c.body&.length.to_i > 15 }
    thoughtfulness_ratio = thoughtful_comments.count.to_f / comments.count

    [0.3, 0.5 + (thoughtfulness_ratio * 0.5)].min
  end
end