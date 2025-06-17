class SupporterProfile < ApplicationRecord
  belongs_to :user

  # 「立場」を配列として扱うためのメソッド
  def standing_array
    standing.to_s.split(',')
  end

  # 「趣味・関心ジャンル」を配列として扱うためのメソッド
  def interests_array
    interests.to_s.split(',')
  end

  # 「支援ジャンル」を配列として扱うためのメソッド
  def support_genres_array
    support_genres.to_s.split(',')
  end

  # 「応援スタイル」を配列として扱うためのメソッド
  def support_styles_array
    support_styles.to_s.split(',')
  end

  # 「性格傾向」を配列として扱うためのメソッド
  def personality_traits_array
    personality_traits.to_s.split(',')
  end
end
