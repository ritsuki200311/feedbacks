# Gemini CLI 行動原則

*   日本語で回答すること。
*   難易度が高い概念については、平易な言葉で説明するか、ユーザーに確認を求めること。
*　　heroku logs --tailについてはなぜか永遠に応答しなくなってしまうので、ユーザーに実行してもらうようにすること
*   できるだけ一回の返答で大きなアウトプットをするように心がけ、geminiが行えるコマンドについては全て行うこと

## AWS S3 設定メモ

### エラー内容
画像アップロード時に `Aws::Errors::MissingCredentialsError` が発生。

### 原因
HerokuアプリケーションにAWS S3へのアクセスに必要な認証情報（Access Key ID, Secret Access Key）およびS3バケット名、リージョンが環境変数として設定されていなかったため。

### 解決策
以下の環境変数をHerokuに設定することで解決。

*   `AWS_ACCESS_KEY_ID`: AWSのアクセスキーID
*   `AWS_SECRET_ACCESS_KEY`: AWSのシークレットアクセスキー
*   `AWS_REGION`: S3バケットが作成されているリージョン (例: `ap-northeast-1`)
*   `S3_BUCKET_NAME`: 使用するS3バケット名 (例: `feedbacks-app-production`)

### 設定コマンド例

```bash
heroku config:set AWS_ACCESS_KEY_ID=YOUR_AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY=YOUR_AWS_SECRET_ACCESS_KEY AWS_REGION=ap-northeast-1 S3_BUCKET_NAME=feedbacks-app-production
```

### バケットの概念

*   **バケット:** AWS S3におけるファイルを保存するためのコンテナ。グローバルに一意な名前を持ち、特定のリージョンに作成される。
*   **`feedbacks-app-development`:** 開発環境用のバケット。テスト目的で使用。
*   **`feedbacks-app-production`:** 本番環境用のバケット。ユーザーが利用するアプリケーションが使用。

**現在の設定:** `S3_BUCKET_NAME` は `feedbacks-app-production` に設定されています。
