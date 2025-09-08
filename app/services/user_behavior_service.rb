# ユーザーの行動履歴分析サービス
class UserBehaviorService
  def initialize(user)
    @user = user
    @cache_key = "user_behavior_#{@user&.id}_#{Time.current.to_date}"
  end

  # ユーザーの行動プロフィールを取得
  def get_behavior_profile
    return {} unless @user

    Rails.cache.fetch(@cache_key, expires_in: 1.hour) do
      calculate_behavior_profile
    end
  end

  # 投稿に対するユーザーの興味度を計算（バズ要素を排除）
  def calculate_interest_score(post)
    return 0.5 unless @user # 未ログインは中立的なスコア

    behavior_profile = get_behavior_profile
    post_tags = extract_tags(post.tag)

    interest_score = 0.5 # ベーススコア

    # 1. タグベースの興味度（コメント・いいね数に依存しない）
    if behavior_profile[:liked_tags]&.any?
      liked_overlap = calculate_tag_overlap(post_tags, behavior_profile[:liked_tags])
      interest_score += liked_overlap * 0.3
    end

    if behavior_profile[:commented_tags]&.any?
      comment_overlap = calculate_tag_overlap(post_tags, behavior_profile[:commented_tags])
      interest_score += comment_overlap * 0.2
    end

    # 2. 創作タイプの好み
    creation_type_bonus = calculate_creation_type_interest(post, behavior_profile)
    interest_score += creation_type_bonus * 0.2

    # 3. 嫌いなタグのペナルティ
    if behavior_profile[:disliked_tags]&.any?
      dislike_overlap = calculate_tag_overlap(post_tags, behavior_profile[:disliked_tags])
      interest_score -= dislike_overlap * 0.3
    end

    # 4. 時間帯の好み（穏やかな要素）
    time_preference_bonus = calculate_time_preference(post)
    interest_score += time_preference_bonus * 0.1

    # 0.0〜1.0の範囲に正規化
    [[0.0, interest_score].max, 1.0].min
  end

  private

  def calculate_behavior_profile
    behavior_data = {}

    begin
      # いいねした投稿のタグを分析（最近50件）
      liked_posts = @user.votes
                         .joins(:votable)
                         .where(value: 1, votable_type: 'Post')
                         .includes(votable: :user)
                         .limit(50)
                         .order(created_at: :desc)

      liked_tags = liked_posts.flat_map do |vote|
        extract_tags(vote.votable.tag)
      end.compact

      behavior_data[:liked_tags] = get_most_frequent_tags(liked_tags, 10)

      # コメントした投稿のタグを分析（最近30件）
      commented_posts = @user.comments
                             .joins(:post)
                             .includes(:post)
                             .limit(30)
                             .order(created_at: :desc)

      commented_tags = commented_posts.flat_map do |comment|
        extract_tags(comment.post.tag)
      end.compact

      behavior_data[:commented_tags] = get_most_frequent_tags(commented_tags, 8)

      # 嫌いな投稿のタグを分析（最近20件）
      disliked_posts = @user.votes
                            .joins(:votable)
                            .where(value: -1, votable_type: 'Post')
                            .includes(votable: :user)
                            .limit(20)
                            .order(created_at: :desc)

      disliked_tags = disliked_posts.flat_map do |vote|
        extract_tags(vote.votable.tag)
      end.compact

      behavior_data[:disliked_tags] = get_most_frequent_tags(disliked_tags, 5)

      # 創作タイプの傾向
      behavior_data[:preferred_creation_types] = analyze_creation_type_preferences

      Rails.logger.debug "Behavior profile calculated for user #{@user.id}: #{behavior_data}"

    rescue => e
      Rails.logger.error "Error calculating behavior profile: #{e.message}"
      behavior_data = {}
    end

    behavior_data
  end

  def analyze_creation_type_preferences
    return [] unless @user

    # いいね・コメントした投稿の創作タイプを分析
    creation_type_counts = Hash.new(0)

    # いいねからの分析
    liked_creation_types = @user.votes
                                .joins(:votable)
                                .where(value: 1, votable_type: 'Post')
                                .group('votable.creation_type')
                                .count

    liked_creation_types.each { |type, count| creation_type_counts[type] += count * 2 }

    # コメントからの分析
    commented_creation_types = @user.comments
                                    .joins(:post)
                                    .group('posts.creation_type')
                                    .count

    commented_creation_types.each { |type, count| creation_type_counts[type] += count }

    # 上位の創作タイプを返す
    creation_type_counts.sort_by { |_, count| -count }
                       .first(3)
                       .map { |type, _| type }
  end

  def calculate_creation_type_interest(post, behavior_profile)
    return 0.0 unless behavior_profile[:preferred_creation_types]&.any?

    if behavior_profile[:preferred_creation_types].include?(post.creation_type)
      0.3
    else
      0.0
    end
  end

  def calculate_time_preference(post)
    # 投稿時間帯の好み（例：平日夜、週末など）
    # 実装は省略、将来的な拡張用
    0.0
  end

  def get_most_frequent_tags(tags, limit = 10)
    return [] if tags.empty?

    tag_counts = tags.each_with_object(Hash.new(0)) { |tag, hash| hash[tag] += 1 }
    tag_counts.sort_by { |_, count| -count }
              .first(limit)
              .map { |tag, _| tag }
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