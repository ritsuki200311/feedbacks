# 投稿間の類似度計算サービス
class PostSimilarityService
  def initialize(user = nil)
    @user = user
    @user_behavior_service = UserBehaviorService.new(user) if user
  end

  # 投稿間の類似度を計算（作品マップ用）
  def calculate_similarity(post1, post2)
    similarity = 0.0
    factors = 0.0

    # 1. タグの類似度 (40%)
    tag_similarity = calculate_tag_similarity(post1, post2)
    if tag_similarity > 0
      similarity += tag_similarity * 0.4
      factors += 0.4
    end

    # 2. カテゴリー類似度 (30%)
    category_similarity = calculate_category_similarity(post1, post2)
    if category_similarity > 0
      similarity += category_similarity * 0.3
      factors += 0.3
    end

    # 3. ユーザー行動ボーナス (10%) - ログインユーザーのみ
    if @user && @user_behavior_service
      behavior_bonus = calculate_user_behavior_bonus(post1, post2)
      if behavior_bonus > 0
        similarity += behavior_bonus * 0.1
        factors += 0.1
      end
    end

    # 4. センチメント類似度 (20%)
    sentiment_similarity = calculate_sentiment_similarity(post1, post2)
    if sentiment_similarity > 0
      similarity += sentiment_similarity * 0.2
      factors += 0.2
    end

    factors > 0 ? similarity / factors : 0.0
  end

  # 複数投稿の類似度マトリックスを計算
  def calculate_similarity_matrix(posts)
    matrix = {}
    posts_array = posts.to_a  # ActiveRecord::RelationをArrayに変換
    
    posts_array.combination(2) do |post1, post2|
      similarity = calculate_similarity(post1, post2)
      matrix["#{post1.id}_#{post2.id}"] = similarity
      matrix["#{post2.id}_#{post1.id}"] = similarity
    end
    
    matrix
  end

  # 階層的マップ用のクラスタリング（より緩い閾値）
  def generate_hierarchical_clusters(posts, zoom_levels = [0.3, 0.15, 0.05])
    posts_array = posts.to_a
    clusters = {}
    
    zoom_levels.each_with_index do |threshold, level|
      clusters["zoom_level_#{level + 1}"] = create_clusters_by_threshold(posts_array, threshold)
    end
    
    Rails.logger.info "Hierarchical clusters generated:"
    clusters.each do |level, level_clusters|
      Rails.logger.info "  #{level}: #{level_clusters.count} clusters"
    end
    
    clusters
  end

  private

  def create_clusters_by_threshold(posts, similarity_threshold)
    visited = Set.new
    clusters = []
    
    posts.each do |post|
      next if visited.include?(post.id)
      
      # 新しいクラスターを作成
      cluster = {
        representative_post: post,
        related_posts: [],
        influence_score: calculate_influence_score(post)
      }
      
      # 類似度がしきい値以上の投稿を同じクラスターに追加
      posts.each do |other_post|
        next if post == other_post || visited.include?(other_post.id)
        
        similarity = calculate_similarity(post, other_post)
        if similarity >= similarity_threshold
          cluster[:related_posts] << other_post
          visited.add(other_post.id)
        end
      end
      
      visited.add(post.id)
      # すべての投稿をクラスターとして保存（単独投稿も含む）
      clusters << cluster
    end
    
    # 影響スコアでソート（代表的な作品を上位に）
    clusters.sort_by { |cluster| -cluster[:influence_score] }
  end

  def calculate_influence_score(post)
    # 影響力を多角的に評価
    score = 0.0
    
    # コメント数（品質重視）
    thoughtful_comments = post.comments.select { |c| c.body&.length.to_i > 15 }.count
    score += thoughtful_comments * 0.3
    
    # 継続的なエンゲージメント（バズではない健全な評価）
    if post.created_at < 1.week.ago
      recent_engagement = post.votes.where('created_at > ?', 1.week.ago).count
      score += recent_engagement * 0.2
    end
    
    # 作者の信頼性（投稿数ベース）
    total_posts = post.user.posts.count
    author_consistency = total_posts >= 5 ? [1.0, Math.log(total_posts) * 0.2].min : 0.4
    score += author_consistency * 0.3
    
    # タグの豊富さ（情報量）
    tag_count = extract_tags(post.tag).count
    score += [tag_count / 5.0, 0.2].min
    
    [score, 1.0].min
  end

  private

  def calculate_tag_similarity(post1, post2)
    tags1 = extract_tags(post1.tag)
    tags2 = extract_tags(post2.tag)
    
    return 0.0 if tags1.empty? || tags2.empty?
    
    common_tags = tags1 & tags2
    total_tags = (tags1 | tags2).size
    
    total_tags > 0 ? common_tags.size.to_f / total_tags : 0.0
  end

  def calculate_category_similarity(post1, post2)
    # 事前定義されたカテゴリーマッピング
    categories = {
      nature: ['自然', '風景', '山', '海', '森', '花', '夕焼け', '夕日'],
      urban: ['都市', '夜景', '建物', '街'],
      seasonal: ['春', '夏', '秋', '冬', '桜'],
      creative: ['アート', 'デザイン', 'イラスト', '音楽']
    }

    post1_categories = get_post_categories(post1, categories)
    post2_categories = get_post_categories(post2, categories)

    return 0.0 if post1_categories.empty? || post2_categories.empty?

    common_categories = post1_categories & post2_categories
    common_categories.any? ? 1.0 : 0.0
  end

  def calculate_user_behavior_bonus(post1, post2)
    return 0.0 unless @user_behavior_service

    behavior_data = @user_behavior_service.get_behavior_profile
    return 0.0 if behavior_data.empty?

    post1_tags = extract_tags(post1.tag)
    post2_tags = extract_tags(post2.tag)

    bonus = 0.0

    # いいねした投稿との類似性ボーナス
    if behavior_data[:liked_tags]&.any?
      liked_match1 = calculate_tag_overlap(post1_tags, behavior_data[:liked_tags])
      liked_match2 = calculate_tag_overlap(post2_tags, behavior_data[:liked_tags])
      
      if liked_match1 > 0 && liked_match2 > 0
        bonus += [liked_match1, liked_match2].min * 0.5
      end
    end

    # 嫌いな投稿のペナルティ
    if behavior_data[:disliked_tags]&.any?
      dislike_match1 = calculate_tag_overlap(post1_tags, behavior_data[:disliked_tags])
      dislike_match2 = calculate_tag_overlap(post2_tags, behavior_data[:disliked_tags])
      
      if dislike_match1 > 0 || dislike_match2 > 0
        bonus -= [dislike_match1, dislike_match2].max * 0.3
      end
    end

    [[0.0, bonus].max, 1.0].min
  end

  def calculate_sentiment_similarity(post1, post2)
    # センチメント分析を無効化（まだ実装されていないため）
    0.0
  end

  def get_post_categories(post, category_mapping)
    post_tags = extract_tags(post.tag)
    categories = []

    category_mapping.each do |category_name, keywords|
      if (post_tags & keywords).any?
        categories << category_name
      end
    end

    categories
  end

  def extract_tags(tag_string)
    return [] if tag_string.blank?
    tag_string.split(',').map(&:strip).reject(&:blank?)
  end

  def calculate_tag_overlap(tags1, tags2)
    return 0.0 if tags1.empty? || tags2.empty?
    intersection = (tags1 & tags2).size
    union = (tags1 | tags2).size
    union > 0 ? intersection.to_f / union : 0.0
  end
end