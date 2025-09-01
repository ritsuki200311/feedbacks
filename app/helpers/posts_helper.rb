module PostsHelper
  def request_tag_options
    [ "見て！感想ください！", "困ってます！アドバイスください！" ]
  end

  def tag_options
    [ "批評ください", "優しい意見ください", "どう感じたのか", "厳しい意見お待ちしています" ]
  end
  
  def feedback_request_options
    [
      "批評ください",
      "優しい意見ください", 
      "どう感じたのか",
      "厳しい意見お待ちしています",
      "リクエスト",
      "見て！",
      "感想ください！",
      "困ってます！",
      "アドバイスください！"
    ]
  end

  def recipient_standing_options
    [ "学生", "社会人", "フリーランス", "アーティスト / クリエイター志望", "その他" ]
  end

  def recipient_creation_experience_options
    [ "自分も創作している", "未経験だが興味がある", "興味なし" ]
  end

  def recipient_interests_options
    [ "音楽", "映像・映画・アニメ", "イラスト・漫画", "ゲーム・実況", "小説・エッセイ", "ファッション・アート", "その他" ]
  end

  def recipient_age_group_options
    [ "～15歳", "16～18歳", "19～22歳", "23～29歳", "30代", "40代以上" ]
  end

  def recipient_support_genres_options
    [ "音楽", "映像・動画", "イラスト・マンガ", "小説・文章", "ゲーム・実況", "ファッション・アート", "舞台・パフォーマンス", "その他" ]
  end

  def recipient_support_styles_options
    [ "金銭的支援をしたい", "感想コメントを書きたい", "SNSで広めたい", "コラボ・アドバイスしたい", "見守りたい", "イベントに参加したい" ]
  end

  def recipient_personality_traits_options
    [ "熱く語りたいタイプ", "静かに応援したい", "質問したい・話しかけたい", "遠くからそっと見ていたい" ]
  end

  def post_card_class(post)
    base_class = "rounded-lg shadow p-6 mb-6"
    case post.request_tag
    when "見て！感想ください！"
      "#{base_class} bg-blue-200"
    when "困ってます！アドバイスください！"
      "#{base_class} bg-red-200"
    else
      "#{base_class} bg-white"
    end
  end
end
