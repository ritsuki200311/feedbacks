# feedbacks

クリエイティブフィードバックプラットフォーム - 創作活動をする人々のためのコミュニティアプリケーション

## 📝 プロジェクト概要

feedbacksは、孤独な創作者を減らし、創作活動を継続できる環境を提供することを目的としたクリエイティブフィードバックプラットフォームです。イラストレーター、ライター、音楽家などのクリエイターが作品を共有し、建設的なフィードバックを受け取ることで、創作への情熱を維持し、技術向上を支援します。

### 主な機能

- 📸 **多種類コンテンツ投稿**: イラスト、文章、音楽など様々な創作物の投稿
- 💬 **画像上コメント機能**: 画像の特定の箇所をクリックしてコメント
- 🏘️ **コミュニティシステム**: テーマ別のコミュニティでの交流
- 🪙 **コイン・ランキングシステム**: 活動に応じたポイント制度
- 💌 **DM機能**: ユーザー間のプライベートメッセージ
- 👍 **投票システム**: 作品への評価機能

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

## 📄 ライセンス・利用について

このプロジェクトは、孤独な創作者を減らし創作活動を支援するためのプラットフォームとして開発されています。

- **目的**: 創作者コミュニティの構築と創作活動の継続支援
- **開発者**: ポートフォリオおよび学習目的を含む
- **商用利用**: 将来的な事業化を予定
- **コード公開**: 技術的な透明性とポートフォリオのため

ソースコードの閲覧・学習目的での参考は歓迎しますが、商用での複製・再配布については事前にご相談ください。
