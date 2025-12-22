# FeedBacks

**「バズるためのSNS」ではなく、「創作を続けるためのSNS」**

クリエイターが作品に対して「評価」ではなく「丁寧なフィードバック」を受け取ることに特化したプラットフォーム

---

## 📝 FeedBacksとは？

FeedBacksは、孤独な創作者を減らし、創作活動を継続できる環境を提供することを目的としたクリエイティブフィードバックプラットフォームです。

**最初のターゲット**: イラスト・写真・絵画分野のクリエイター

従来のSNSでは、作品は不特定多数に拡散され、数値的な「評価」が中心となります。しかしFeedBacksは、**少人数による質の高いフィードバック**を重視し、創作者が「共感してくれる人に見てほしい」というニーズに応えます。

---

## 🎯 FeedBacksの8つの特徴

### 1. 少人数マッチング型フィードバック
投稿された作品は、不特定多数に一気に拡散されるのではなく、**興味・専門性・信頼度などをもとにマッチングされた少人数（数人〜十数人）のユーザーに届けられます**。

「評価される前に、共感してくれる人に見てほしい」というクリエイターのニーズを重視しています。

### 2. コメント中心の設計
**いいねよりもコメントを重視した設計**で、長文・具体的な感想が歓迎されます。

コメントは作品理解・制作意図・改善点などを伝えることを目的としています。

### 3. ピンコメント機能
視聴者は、**作品画像の特定位置にピンを立ててコメントを紐づける**ことができます。

- 「この部分の光の表現が素晴らしい」
- 「ここの構図がもう少し改善できそう」

といった具体的なフィードバックが可能になります。

**注**: ピンコメントは視聴者側のみが操作し、作者は操作しません。

### 4. 信頼度システム
ユーザーには**信頼度スコア**があり、以下の行動で信頼度が上がります：

- 良質なコメントの投稿
- コメント数が少ない投稿へのコメント
- 継続的な活動

信頼度はコメントや投稿の表示順位、マッチング精度に影響します。

信頼度が下がりすぎると、実質的な**シャドウバン状態**になります。

### 5. コメントコイン制度
**コメントを書くことでコインを獲得**でき、コインは投稿や一部機能の利用に関係します。

反応の少ない投稿にコメントすると、**より多くのリターン**が得られる仕組みで、フィードバックの偏りを防ぎます。

### 6. AIコメント補助
コメントを書くのが苦手なユーザー向けに、**作品内容を踏まえたコメント補助AI**を搭載します。

ただし、最終的な文章はユーザー自身が投稿します。

### 7. 反応の少ない投稿を救うアルゴリズム
**コメント数が少ない投稿を優先的に表示・マッチング**し、フィードバックが偏らないように設計されています。

すべてのクリエイターが等しくフィードバックを受け取れる環境を目指します。

### 8. 収益化機能（アフィリエイト）
投稿には、**使用した画材・機材・アイテム情報とアフィリエイトリンク**を掲載できます。

閲覧者のクリックや購入によって、投稿者に収益が入ります。

Amazon以外のアフィリエイトURLにも対応します。

---

## 💡 FeedBacksのビジョン

> **「バズるためのSNS」ではなく、「創作を続けるためのSNS」を目指しています。**

FeedBacksは、数値的な評価や拡散ではなく、**質の高いフィードバック**と**継続的な創作活動の支援**を最優先にしたプラットフォームです。

## 🛠 技術スタック

- **Backend**: Ruby 3.4.2 + Rails 8.0.1
- **Database**: PostgreSQL (JSONB活用)
- **Frontend**: 
  - Tailwind CSS (スタイリング)
  - Stimulus (JavaScript フレームワーク)
  - Turbo (SPA-like ナビゲーション)
  - Importmaps (JavaScript モジュール管理)
- **Storage**: Amazon S3 (ファイルストレージ)
- **Deployment**: Heroku
- **Authentication**: Devise

## 🚀 セットアップ

### 必要な環境
- Ruby 3.4.2
- PostgreSQL
- Node.js (Importmaps用)
- AWS S3アカウント (ファイルストレージ用)

### インストール手順

1. リポジトリをクローン
```bash
git clone https://github.com/your-repo/feedbacks.git
cd feedbacks
```

2. 依存関係をインストール
```bash
bundle install
```

3. データベースを作成・マイグレーション
```bash
bin/rails db:create db:migrate
```

4. 初期データを投入（オプション）
```bash
bin/rails db:seed
```

5. 環境変数を設定
```bash
# AWS S3設定
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_REGION=your_region
export AWS_BUCKET_NAME=your_bucket_name
```

## 🏃‍♂️ 開発コマンド

### アプリケーション起動
```bash
# 基本起動
bin/rails server

# 開発環境（Foremanを使用）
foreman start -f Procfile.dev
```

### テスト実行
```bash
# 全テストを実行
bin/rails test

# システムテスト（特定のデータベースユーザーで実行）
export TEST_DATABASE_USERNAME=akimotoritsuki && bin/rails test:system

# 特定のテストファイルを実行
bin/rails test test/controllers/posts_controller_test.rb
```

### データベース操作
```bash
# データベースリセット
bin/rails db:reset

# マイグレーション実行
bin/rails db:migrate
```

### コード品質チェック
```bash
# RuboCop（リンティング）
bundle exec rubocop

# Brakeman（セキュリティ解析）
bundle exec brakeman
```

### アセット管理
```bash
# Tailwind CSSをビルド
bin/rails tailwindcss:build

# アセットをプリコンパイル
bin/rails assets:precompile
```

## 🌐 デプロイ

### Herokuデプロイ

1. Herokuアプリを作成
```bash
heroku create your-app-name
```

2. PostgreSQLアドオンを追加
```bash
heroku addons:create heroku-postgresql:essential-0
```

3. 環境変数を設定
```bash
heroku config:set AWS_ACCESS_KEY_ID=your_access_key
heroku config:set AWS_SECRET_ACCESS_KEY=your_secret_key
heroku config:set AWS_REGION=your_region
heroku config:set AWS_BUCKET_NAME=your_bucket_name
```

4. デプロイ
```bash
git push heroku main
```

5. データベースマイグレーション
```bash
heroku run bin/rails db:migrate
```

### ファイルストレージ

- **本番環境**: Amazon S3を使用
- **開発環境**: ローカルストレージ
- **対応形式**:
  - 画像: JPEG, PNG, GIF (最大5MB)
  - 動画: MP4, MOV, AVI (最大500MB)
  - 音声: MP3, WAV, OGG (最大100MB)
 
### 現在のデプロイリンク(更新が少し前で最新の仕様とと乖離があります)
https://abesora-feedbacks-2025-83f668d5f30b.herokuapp.com/


## 補足資料

- **事業スライド（PDF）**  
  プロジェクトの背景や狙い・成果をまとめた資料です。  
  ※要約：創作者の孤独を解決するための企画、主要ユーザーや背景・現状分析など  
  [スライドはこちら（PDFを表示／ダウンロード）](https://github.com/user-attachments/files/21727597/Web.pdf)

<details>
  <summary>画面イメージ・スクリーンショットを見る</summary>

  <img src="https://github.com/user-attachments/assets/b7a900e5-7b85-44fa-b176-a6dd4a42034f" alt="トップ画面" width="700" />

  <img src="https://github.com/user-attachments/assets/61a663b4-d078-452c-aa12-fb226fd05009" alt="投稿閲覧画面（縦画面のレスポンシブデザイン／AIコメント補助）" width="400" />

</details>


## 📄 ライセンス・利用について

このプロジェクトは、孤独な創作者を減らし創作活動を支援するためのプラットフォームとして開発されています。

- **目的**: 創作者コミュニティの構築と創作活動の継続支援
- **開発者**: ポートフォリオおよび学習目的を含む
- **商用利用**: 将来的な事業化を予定
- **コード公開**: 技術的な透明性とポートフォリオのため

ソースコードの閲覧・学習目的での参考は歓迎しますが、商用での複製・再配布については事前にご相談ください。
