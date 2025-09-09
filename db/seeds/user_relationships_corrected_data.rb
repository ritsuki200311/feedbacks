# 実際のプロフィール属性に合わせた正しいテストデータ
puts "Creating corrected test users for user relationships visualization..."

# 実際のプロフィール構造に基づくテストデータ（類似度のバリエーション付き）
corrected_test_profiles = [
  # 【音楽系クラスター - 高い類似度】
  {
    name: "音楽愛好家A",
    email: "music_lover_a@example.com",
    standing: "学生",
    creation_experience: "バンド活動3年、作曲経験あり",
    interests: "音楽, ライブ・コンサート",
    favorite_artists: "米津玄師, あいみょん, King Gnu",
    age_group: "19～22歳",
    support_genres: "音楽",
    support_styles: "金銭的支援をしたい, 感想コメントを書きたい",
    personality_traits: "熱く語りたいタイプ"
  },
  {
    name: "音楽制作者B",
    email: "music_creator_b@example.com",
    standing: "社会人",
    creation_experience: "DTM歴5年、インディーズ活動中",
    interests: "音楽, DTM・作曲",
    favorite_artists: "BUMP OF CHICKEN, 福山雅治, サカナクション",
    age_group: "23～26歳",
    support_genres: "音楽",
    support_styles: "SNSでシェアしたい, 感想コメントを書きたい",
    personality_traits: "静かに応援したいタイプ"
  },
  {
    name: "音楽ファンC",
    email: "music_fan_c@example.com",
    standing: "学生",
    creation_experience: "楽器演奏歴2年",
    interests: "音楽, ライブ・コンサート",
    favorite_artists: "Official髭男dism, Ado, YOASOBI",
    age_group: "19～22歳",
    support_genres: "音楽",
    support_styles: "金銭的支援をしたい, 拡散・宣伝を手伝いたい",
    personality_traits: "熱く語りたいタイプ"
  },

  # 【イラスト・漫画系クラスター - 高い類似度】
  {
    name: "イラスト描きA",
    email: "illustrator_a@example.com",
    standing: "学生",
    creation_experience: "デジタルイラスト歴4年、同人誌制作経験あり",
    interests: "イラスト・漫画, デジタルアート",
    favorite_artists: "鬼滅の刃, 呪術廻戦, SPY×FAMILY",
    age_group: "19～22歳",
    support_genres: "イラスト・漫画",
    support_styles: "感想コメントを書きたい, 作品をコレクションしたい",
    personality_traits: "じっくり鑑賞したいタイプ"
  },
  {
    name: "漫画愛好家B",
    email: "manga_lover_b@example.com",
    standing: "社会人",
    creation_experience: "漫画レビュー歴3年",
    interests: "イラスト・漫画, アニメ",
    favorite_artists: "ONE PIECE, 進撃の巨人, 東京卍リベンジャーズ",
    age_group: "27～30歳",
    support_genres: "イラスト・漫画",
    support_styles: "金銭的支援をしたい, 感想コメントを書きたい",
    personality_traits: "熱く語りたいタイプ"
  },
  {
    name: "アート好きC",
    email: "art_lover_c@example.com",
    standing: "学生",
    creation_experience: "アナログ絵画歴6年",
    interests: "イラスト・漫画, アート・美術",
    favorite_artists: "ジブリ作品, 新海誠作品",
    age_group: "19～22歳",
    support_genres: "イラスト・漫画",
    support_styles: "作品をコレクションしたい, SNSでシェアしたい",
    personality_traits: "静かに応援したいタイプ"
  },

  # 【映像・映画系クラスター - 中程度の類似度】
  {
    name: "映画好きA",
    email: "movie_lover_a@example.com",
    standing: "社会人",
    creation_experience: "動画編集歴2年、YouTubeチャンネル運営",
    interests: "映像・映画・アニメ, 動画制作",
    favorite_artists: "宮崎駿作品, 新海誠作品, Marvel映画",
    age_group: "23～26歳",
    support_genres: "映像・動画",
    support_styles: "SNSでシェアしたい, 感想コメントを書きたい",
    personality_traits: "じっくり鑑賞したいタイプ"
  },
  {
    name: "アニメファンB",
    email: "anime_fan_b@example.com",
    standing: "学生",
    creation_experience: "アニメレビュー歴1年",
    interests: "映像・映画・アニメ, アニメ",
    favorite_artists: "鬼滅の刃, 呪術廻戦, チェンソーマン",
    age_group: "19～22歳",
    support_genres: "映像・動画",
    support_styles: "感想コメントを書きたい, 拡散・宣伝を手伝いたい",
    personality_traits: "熱く語りたいタイプ"
  },

  # 【小説・文章系クラスター - 中程度の類似度】
  {
    name: "小説愛読家A",
    email: "novel_reader_a@example.com",
    standing: "社会人",
    creation_experience: "小説投稿サイトでの活動歴3年",
    interests: "小説・文学, 読書",
    favorite_artists: "東野圭吾, 湊かなえ, 村上春樹",
    age_group: "27～30歳",
    support_genres: "小説・文章",
    support_styles: "金銭的支援をしたい, 感想コメントを書きたい",
    personality_traits: "じっくり鑑賞したいタイプ"
  },
  {
    name: "文章書きB",
    email: "writer_b@example.com",
    standing: "学生",
    creation_experience: "ブログ執筆歴2年、小説同人誌制作",
    interests: "小説・文学, ブログ・エッセイ",
    favorite_artists: "又吉直樹, 朝井リョウ, 森見登美彦",
    age_group: "19～22歳",
    support_genres: "小説・文章",
    support_styles: "感想コメントを書きたい, 作品をコレクションしたい",
    personality_traits: "静かに応援したいタイプ"
  },

  # 【複合ジャンル - 中程度の類似度】
  {
    name: "マルチファンA",
    email: "multi_fan_a@example.com",
    standing: "学生",
    creation_experience: "趣味で幅広く活動",
    interests: "音楽, イラスト・漫画, ゲーム",
    favorite_artists: "ボカロ楽曲, ゲーム音楽",
    age_group: "19～22歳",
    support_genres: "音楽, イラスト・漫画",
    support_styles: "金銭的支援をしたい, SNSでシェアしたい",
    personality_traits: "熱く語りたいタイプ"
  },
  {
    name: "クリエイティブB",
    email: "creative_b@example.com",
    standing: "社会人",
    creation_experience: "動画・音楽制作の複合活動",
    interests: "音楽, 映像・映画・アニメ",
    favorite_artists: "米津玄師のMV, アニメOP・ED",
    age_group: "23～26歳",
    support_genres: "音楽, 映像・動画",
    support_styles: "感想コメントを書きたい, 拡散・宣伝を手伝いたい",
    personality_traits: "じっくり鑑賞したいタイプ"
  },

  # 【完全に異なるジャンル - 低い類似度】
  {
    name: "スポーツファンA",
    email: "sports_fan_a@example.com",
    standing: "社会人",
    creation_experience: "スポーツ観戦ブログ運営",
    interests: "スポーツ観戦",
    favorite_artists: "野球, サッカー, バスケットボール",
    age_group: "31～35歳",
    support_genres: "その他",
    support_styles: "金銭的支援をしたい",
    personality_traits: "熱く語りたいタイプ"
  },
  {
    name: "料理研究家B",
    email: "cooking_fan_b@example.com",
    standing: "主婦・主夫",
    creation_experience: "料理レシピ開発5年",
    interests: "料理・グルメ",
    favorite_artists: "料理番組, グルメ番組",
    age_group: "27～30歳",
    support_genres: "その他",
    support_styles: "SNSでシェアしたい",
    personality_traits: "静かに応援したいタイプ"
  },
  {
    name: "旅行愛好家C",
    email: "travel_fan_c@example.com",
    standing: "社会人",
    creation_experience: "旅行ブログ執筆歴3年",
    interests: "旅行",
    favorite_artists: "各地の観光スポット, 世界遺産",
    age_group: "27～30歳",
    support_genres: "その他",
    support_styles: "作品をコレクションしたい",
    personality_traits: "じっくり鑑賞したいタイプ"
  }
]

# 既存のテストユーザーを削除（開発環境のみ）
if Rails.env.development?
  puts "Deleting all existing test users..."
  # 以前作成したテストユーザーを削除
  User.where(email: [
    "tanaka@example.com", "sato@example.com", "suzuki@example.com", "takahashi@example.com",
    "yamada@example.com", "nakamura@example.com", "kobayashi@example.com", "kato@example.com",
    "watanabe@example.com", "ito@example.com", "kimura@example.com", "ishikawa@example.com",
    "aoki@example.com", "nishida@example.com", "matsumoto@example.com", "hashimoto@example.com",
    "morita@example.com", "okada@example.com", "saito@example.com", "fukuda@example.com"
  ] + corrected_test_profiles.map { |p| p[:email] }).destroy_all
end

# 正しいプロフィール構造でテストユーザーを作成
corrected_test_profiles.each_with_index do |profile_data, index|
  puts "Creating user #{index + 1}/#{corrected_test_profiles.length}: #{profile_data[:name]}"

  # ユーザーを作成
  user = User.create!(
    name: profile_data[:name],
    email: profile_data[:email],
    password: "password123",
    password_confirmation: "password123"
  )

  # 実際の属性に基づいてプロフィールを作成
  user.create_supporter_profile!(
    standing: profile_data[:standing],
    creation_experience: profile_data[:creation_experience],
    interests: profile_data[:interests],
    favorite_artists: profile_data[:favorite_artists],
    age_group: profile_data[:age_group],
    support_genres: profile_data[:support_genres],
    support_styles: profile_data[:support_styles],
    personality_traits: profile_data[:personality_traits]
  )

  puts "  ✅ Created #{user.name} with correct profile structure"
end

puts "\n🎉 Successfully created #{corrected_test_profiles.length} users with correct profile structure!"
puts "You can now test the user relationships visualization feature with proper similarity calculations."
