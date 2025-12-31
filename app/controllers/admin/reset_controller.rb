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

  def delete_all_posts
    count = Post.count
    Post.destroy_all

    render json: {
      message: "すべての投稿を削除しました",
      deleted_count: count,
      current_count: Post.count
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
      raise_delivery_errors: Rails.configuration.action_mailer.raise_delivery_errors,
      smtp_settings: Rails.configuration.action_mailer.smtp_settings
    }

    # テストメール送信
    delivery_info = nil
    begin
      # テスト用メールを送信
      test_email = params[:email] || "test@example.com"

      # 一時的にエラーを発生させる設定
      original_raise_errors = ActionMailer::Base.raise_delivery_errors
      ActionMailer::Base.raise_delivery_errors = true

      # 簡単なテストメーラーを使用
      mail = TestMailer.test_message(test_email)
      delivery_info = mail.deliver_now

      # 設定を戻す
      ActionMailer::Base.raise_delivery_errors = original_raise_errors

      result = {
        success: true,
        message: "テストメール送信成功",
        delivery_info: delivery_info.inspect
      }
    rescue => e
      # 設定を戻す
      ActionMailer::Base.raise_delivery_errors = original_raise_errors if defined?(original_raise_errors)

      result = {
        success: false,
        error: e.message,
        error_class: e.class.name,
        backtrace: e.backtrace.first(10)
      }
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
