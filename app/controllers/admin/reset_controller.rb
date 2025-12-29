class Admin::ResetController < ApplicationController
  # セキュリティ: 特定のトークンがないとアクセスできない
  before_action :verify_reset_token

  def reset_users
    count = User.count
    User.destroy_all

    render json: {
      message: "すべてのユーザーを削除しました",
      deleted_count: count,
      current_count: User.count
    }
  end

  def test_email
    # 環境変数の確認
    env_info = {
      resend_api_key_present: ENV['RESEND_API_KEY'].present?,
      resend_api_key_prefix: ENV['RESEND_API_KEY']&.slice(0, 5),
      mailer_sender: ENV['MAILER_SENDER'],
      app_host: ENV['APP_HOST'],
      delivery_method: Rails.configuration.action_mailer.delivery_method,
      perform_deliveries: Rails.configuration.action_mailer.perform_deliveries,
      raise_delivery_errors: Rails.configuration.action_mailer.raise_delivery_errors
    }

    # テストメール送信
    begin
      # テスト用メールを送信
      test_email = params[:email] || "test@example.com"

      # 簡単なテストメーラーを使用
      TestMailer.test_message(test_email).deliver_now

      result = { success: true, message: "テストメール送信を試みました" }
    rescue => e
      result = { success: false, error: e.message, backtrace: e.backtrace.first(5) }
    end

    render json: {
      environment_variables: env_info,
      test_result: result
    }
  end

  private

  def verify_reset_token
    # 環境変数で設定したトークンと一致するかチェック
    unless params[:token] == ENV['RESET_TOKEN']
      render json: { error: "Invalid token" }, status: :unauthorized
    end
  end
end
