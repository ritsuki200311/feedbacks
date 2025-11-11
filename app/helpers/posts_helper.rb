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
    [ "1年未満", "1-3年", "4-6年", "7-10年", "10年以上", "経験なし" ]
  end

  def recipient_interests_options
    [ "イラスト・絵画", "マンガ・コミック", "小説・詩・エッセイ", "音楽制作・作詞作曲", "映像制作・動画編集", "ゲーム制作・プログラミング", "デザイン・グラフィック", "写真・撮影技術", "舞台・演劇・パフォーマンス", "手芸・クラフト", "その他" ]
  end

  def recipient_age_group_options
    [ "～15歳", "16～18歳", "19～22歳", "23～29歳", "30代", "40代以上" ]
  end

  def recipient_support_genres_options
    [ "イラスト・絵画", "マンガ・コミック", "小説・詩・エッセイ", "音楽制作・作詞作曲", "映像制作・動画編集", "ゲーム制作・プログラミング", "デザイン・グラフィック", "写真・撮影技術", "舞台・演劇・パフォーマンス", "手芸・クラフト", "その他", "していない" ]
  end

  def recipient_support_styles_options
    [ "金銭的支援をしたい", "感想コメントを書きたい", "SNSで広めたい", "コラボ・アドバイスしたい", "見守りたい", "イベントに参加したい" ]
  end

  def recipient_personality_traits_options
    [ "熱く語りたいタイプ", "静かに応援したい", "質問したい・話しかけたい", "遠くからそっと見ていたい" ]
  end

  def post_card_class(post)
    base_class = "p-3 mb-3 border-b border-gray-200 md:rounded-lg md:shadow md:border-0"
    case post.request_tag
    when "見て！感想ください！"
      "#{base_class} bg-blue-50 md:bg-blue-200"
    when "困ってます！アドバイスください！"
      "#{base_class} bg-red-50 md:bg-red-200"
    else
      "#{base_class} bg-white"
    end
  end
end
