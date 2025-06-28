class SupporterProfile < ApplicationRecord
  belongs_to :user

  # 立場を配列として取得
  def standing_array
    standing.to_s.split(',').map(&:strip).reject(&:blank?)
  end

  # 趣味・関心ジャンル
  def interests_array
    interests.to_s.split(',').map(&:strip).reject(&:blank?)
  end

  # 支援したいジャンル
  def support_genres_array
    support_genres.to_s.split(',').map(&:strip).reject(&:blank?)
  end

  # 応援スタイル
  def support_styles_array
    support_styles.to_s.split(',').map(&:strip).reject(&:blank?)
  end

  # 性格傾向
  def personality_traits_array
    personality_traits.to_s.split(',').map(&:strip).reject(&:blank?)
  end

  # 年齢層（単一値だが、nil安全性のためにメソッド化）
  def age_group_value
    age_group.to_s
  end
end
