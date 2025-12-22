# Renderへのデプロイ手順

## 事前準備

### 1. Renderアカウントの作成
1. [Render](https://render.com/)にアクセス
2. GitHubアカウントでサインアップ

### 2. 必要な環境変数の準備

#### RAILS_MASTER_KEY の取得
```bash
cat config/master.key
```
このキーをコピーしておいてください。

#### Google Gemini API Key（必要な場合）
`.env`ファイルから`GOOGLE_GEMINI_API_KEY`を取得

#### AWS S3の設定（画像アップロードに必要）
`.env`ファイルから以下を取得：
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `AWS_BUCKET`

## デプロイ手順

### ステップ1: GitHubにプッシュ

```bash
# 変更をコミット
git add .
git commit -m "Renderデプロイ設定を追加"
git push origin main
```

### ステップ2: Renderでプロジェクトを作成

1. [Render Dashboard](https://dashboard.render.com/)にログイン
2. 「New +」→「Blueprint」をクリック
3. GitHubリポジトリを接続
4. `feedbacks`リポジトリを選択
5. `render.yaml`が自動的に検出されます
6. 「Apply」をクリック

### ステップ3: 環境変数の設定

Renderのダッシュボードで、作成された「feedbacks」サービスを開き、「Environment」タブで以下を設定：

**必須の環境変数:**
```
RAILS_MASTER_KEY=（先ほどコピーしたキー）
```

**オプション（機能に応じて）:**
```
GOOGLE_GEMINI_API_KEY=your_gemini_api_key
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key
AWS_REGION=ap-northeast-1
AWS_BUCKET=your_bucket_name
```

### ステップ4: デプロイ

環境変数を設定後、Renderが自動的にデプロイを開始します。

ログを確認：
- 「Logs」タブでビルドとデプロイの進行状況を確認
- エラーがあれば修正してプッシュ

### ステップ5: データベースのマイグレーション

初回デプロイ後、データベースが自動的にマイグレーションされます（`render-build.sh`で実行）。

## デプロイ後の確認

1. Renderが提供するURL（例: `https://feedbacks-xxxx.onrender.com`）にアクセス
2. アプリが正常に動作することを確認

## 注意事項

### 無料プランの制限
- **非アクティブ時のスリープ**: 15分間アクセスがないとスリープモードになります
- **起動時間**: スリープから起動まで30秒〜1分かかります
- **データベース**: 無料プランは90日間のみ
- **ストレージ**: 静的ファイルは再デプロイ時にリセットされます

### おすすめの対策
1. **画像ストレージ**: AWS S3やCloudinaryを使用（必須）
2. **定期アクセス**: UptimeRobotなどでスリープを防ぐ（オプション）

## トラブルシューティング

### デプロイが失敗する場合

**1. ビルドエラー**
```bash
# ローカルで本番環境のビルドをテスト
RAILS_ENV=production bundle exec rails assets:precompile
```

**2. データベース接続エラー**
- Renderのダッシュボードで`feedbacks-db`が正常に作成されているか確認
- `DATABASE_URL`環境変数が正しく設定されているか確認

**3. アセットが表示されない**
- `RAILS_SERVE_STATIC_FILES=enabled`が設定されているか確認
- ビルドログで`assets:precompile`が成功しているか確認

### ログの確認方法
```
Renderダッシュボード → サービス → Logs
```

## 更新とデプロイ

コードを更新する場合：

```bash
# 変更をコミット
git add .
git commit -m "機能追加"
git push origin main
```

Renderが自動的に新しいバージョンをデプロイします。

## 環境変数の追加

新しい環境変数を追加する場合：

1. Renderダッシュボード → サービス → Environment
2. 「Add Environment Variable」をクリック
3. キーと値を入力
4. 「Save Changes」→ 自動的に再デプロイ

## 参考リンク

- [Render公式ドキュメント](https://render.com/docs)
- [Rails on Renderガイド](https://render.com/docs/deploy-rails)
