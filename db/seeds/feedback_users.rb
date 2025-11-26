# フィードバック用ユーザーデータ作成
require_relative '../../config/environment' unless defined?(Rails)

puts "フィードバック専門ユーザーを作成中..."

# イラスト・マンガ・デザイン専門ユーザー（6人）
illustration_users = [
  {
    name: "アート・みなみ",
    email: "art.minami@example.com",
    password: "password123",
    rank: "B",
    rank_points: 350,
    coins: 1500,
    profile: {
      age_group: "20代",
      support_genres: ["イラスト・絵画"],
      creation_experience: "5年以上",
      interests: ["キャラクターデザイン", "デジタルアート", "色彩理論"],
      favorite_artists: "キャラクターの表情や構図、色使いについて具体的なアドバイスができます。特にデジタルツールの使い方や効果的な演出方法に詳しいです。"
    }
  },
  {
    name: "イラストの達人",
    email: "illust.master@example.com",
    password: "password123",
    rank: "A",
    rank_points: 720,
    coins: 2200,
    profile: {
      age_group: "30代",
      support_genres: ["イラスト・絵画"],
      creation_experience: "10年以上",
      interests: ["背景描画", "ライティング", "コンセプトアート"],
      favorite_artists: "背景の描き方、光と影の表現、構図の取り方について詳しくフィードバックできます。商業イラストの経験も豊富です。"
    }
  },
  {
    name: "まんが先生",
    email: "manga.sensei@example.com",
    password: "password123",
    rank: "A",
    rank_points: 650,
    coins: 1800,
    profile: {
      age_group: "40代",
      support_genres: ["マンガ・コミック"],
      creation_experience: "15年以上",
      interests: ["ストーリー構成", "キャラクター設定", "コマ割り"],
      favorite_artists: "漫画のストーリー構成、キャラクターの魅力、読みやすいコマ割りなど、漫画制作の全般についてアドバイスできます。"
    }
  },
  {
    name: "デザイン・プロ",
    email: "design.pro@example.com",
    password: "password123",
    rank: "A",
    rank_points: 580,
    coins: 1700,
    profile: {
      age_group: "30代",
      support_genres: ["デザイン・グラフィック"],
      creation_experience: "8年以上",
      interests: ["タイポグラフィ", "レイアウトデザイン", "ブランディング"],
      favorite_artists: "ロゴ、ポスター、ウェブデザインなどの視覚的コミュニケーションについてフィードバックできます。商業デザインの実務経験豊富です。"
    }
  },
  {
    name: "フォト・アーティスト",
    email: "photo.artist@example.com",
    password: "password123",
    rank: "B",
    rank_points: 420,
    coins: 1400,
    profile: {
      age_group: "20代",
      support_genres: ["写真・撮影技術"],
      creation_experience: "6年以上",
      interests: ["ポートレート撮影", "風景撮影", "レタッチ技術"],
      favorite_artists: "構図、光の使い方、被写体との関係性について具体的なアドバイスができます。RAW現像やPhotoshopでの加工技術も詳しいです。"
    }
  },
  {
    name: "クラフト職人",
    email: "craft.shokunin@example.com",
    password: "password123",
    rank: "B",
    rank_points: 380,
    coins: 1200,
    profile: {
      age_group: "40代",
      support_genres: ["手芸・クラフト"],
      creation_experience: "12年以上",
      interests: ["陶芸", "木工", "レザークラフト"],
      favorite_artists: "手作り作品の技法、材料の選び方、仕上げのコツについてアドバイスできます。伝統工芸から現代的なクラフトまで幅広く対応します。"
    }
  }
]

# 文章・映像・舞台・ゲーム専門ユーザー（6人）
writing_users = [
  {
    name: "文章の匠",
    email: "writing.master@example.com",
    password: "password123",
    rank: "A",
    rank_points: 680,
    coins: 1900,
    profile: {
      age_group: "30代",
      support_genres: ["小説・詩・エッセイ"],
      creation_experience: "8年以上",
      interests: ["文体分析", "構成技法", "キャラクター心理"],
      favorite_artists: "文章の流れ、表現技法、キャラクターの心理描写について具体的なフィードバックができます。特に読者に響く文章作りが得意です。"
    }
  },
  {
    name: "詩人のこころ",
    email: "poet.heart@example.com",
    password: "password123",
    rank: "B",
    rank_points: 420,
    coins: 1300,
    profile: {
      age_group: "20代",
      support_genres: ["小説・詩・エッセイ"],
      creation_experience: "3年以上",
      interests: ["詩的表現", "リズム感", "言葉選び"],
      favorite_artists: "詩の韻律やリズム、言葉の響きや選び方について繊細なフィードバックができます。感情表現の技法に詳しいです。"
    }
  },
  {
    name: "映像クリエイター",
    email: "video.creator@example.com",
    password: "password123",
    rank: "A",
    rank_points: 600,
    coins: 1800,
    profile: {
      age_group: "30代",
      support_genres: ["映像制作・動画編集"],
      creation_experience: "7年以上",
      interests: ["映像編集", "撮影技法", "ストーリーボード"],
      favorite_artists: "動画の構成、カット割り、音と映像の関係について専門的なアドバイスができます。YouTube、SNS動画から映画まで幅広く対応します。"
    }
  },
  {
    name: "ステージアーティスト",
    email: "stage.artist@example.com",
    password: "password123",
    rank: "B",
    rank_points: 450,
    coins: 1400,
    profile: {
      age_group: "20代",
      support_genres: ["舞台・演劇・パフォーマンス"],
      creation_experience: "6年以上",
      interests: ["演技技法", "舞台演出", "身体表現"],
      favorite_artists: "演技の表現力、舞台での立ち位置、観客との関係性について実践的なアドバイスができます。演劇からダンスまで幅広く対応します。"
    }
  },
  {
    name: "ゲームデベロッパー",
    email: "game.dev@example.com",
    password: "password123",
    rank: "A",
    rank_points: 720,
    coins: 2100,
    profile: {
      age_group: "30代",
      support_genres: ["ゲーム制作・プログラミング"],
      creation_experience: "10年以上",
      interests: ["ゲームデザイン", "プログラミング", "UI・UX"],
      favorite_artists: "ゲームの企画、プログラミング技術、ユーザビリティについて技術的・クリエイティブ両面からフィードバックできます。"
    }
  },
  {
    name: "その他クリエイター",
    email: "other.creator@example.com",
    password: "password123",
    rank: "B",
    rank_points: 350,
    coins: 1200,
    profile: {
      age_group: "40代",
      support_genres: ["その他"],
      creation_experience: "5年以上",
      interests: ["創作全般", "アイデア発想", "表現技法"],
      favorite_artists: "ジャンルを問わず、創作活動全般についてサポートします。新しい表現方法やアイデアの発想について一緒に考えます。"
    }
  }
]

# 音楽専門ユーザー（3人）
music_users = [
  {
    name: "サウンド・クリエイター",
    email: "sound.creator@example.com",
    password: "password123",
    rank: "A",
    rank_points: 750,
    coins: 2000,
    profile: {
      age_group: "30代",
      support_genres: ["音楽制作・作詞作曲"],
      creation_experience: "12年以上",
      interests: ["楽曲アレンジ", "ミキシング", "音響効果"],
      favorite_artists: "楽曲のアレンジ、音の質感、ミキシングバランスについて技術的なフィードバックができます。DTMソフトの使い方も詳しいです。"
    }
  },
  {
    name: "メロディメイカー",
    email: "melody.maker@example.com",
    password: "password123",
    rank: "B",
    rank_points: 450,
    coins: 1400,
    profile: {
      age_group: "20代",
      support_genres: ["音楽制作・作詞作曲"],
      creation_experience: "4年以上",
      interests: ["作曲", "和声理論", "楽器演奏"],
      favorite_artists: "メロディライン、コード進行、楽曲の構成について理論と感性の両面からフィードバックできます。様々な楽器の知識があります。"
    }
  },
  {
    name: "音楽プロデューサー",
    email: "music.producer@example.com",
    password: "password123",
    rank: "A",
    rank_points: 820,
    coins: 2400,
    profile: {
      age_group: "40代",
      support_genres: ["音楽制作・作詞作曲"],
      creation_experience: "20年以上",
      interests: ["音楽プロデュース", "ジャンル分析", "マーケティング"],
      favorite_artists: "楽曲の商業的価値、ターゲット層への響き、音楽業界での位置づけなど、プロデューサー視点でのアドバイスができます。"
    }
  }
]

# 全ユーザーを統合
all_users = illustration_users + writing_users + music_users

all_users.each_with_index do |user_data, index|
  # ユーザー作成
  user = User.find_or_create_by(email: user_data[:email]) do |u|
    u.name = user_data[:name]
    u.password = user_data[:password]
    u.rank_points = user_data[:rank_points]
    u.coins = user_data[:coins]
    u.confirmed_at = Time.current # Deviseの確認済み状態に設定
  end

  # 既存ユーザーの場合は値を更新
  unless user.persisted?
    user.update!(
      name: user_data[:name],
      rank_points: user_data[:rank_points],
      coins: user_data[:coins]
    )
  end

  # プロフィール作成/更新
  profile = user.supporter_profile || user.build_supporter_profile

  profile.update!(
    age_group: user_data[:profile][:age_group],
    support_genres: user_data[:profile][:support_genres],
    creation_experience: user_data[:profile][:creation_experience],
    interests: user_data[:profile][:interests],
    favorite_artists: user_data[:profile][:favorite_artists]
  )

  puts "✓ #{user.name} (#{user.rank}ランク) - #{user_data[:profile][:support_genres].join(', ')}専門"
end

puts "\n=== 作成完了 ==="
puts "イラスト・絵画・マンガ・デザイン・写真・クラフト専門: 6人"
puts "小説・詩・映像・舞台・ゲーム・その他専門: 6人"
puts "音楽制作専門: 3人"
puts "合計: #{all_users.length}人のフィードバック専門ユーザーを作成しました！"