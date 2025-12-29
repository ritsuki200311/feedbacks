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

  private

  def verify_reset_token
    # 環境変数で設定したトークンと一致するかチェック
    unless params[:token] == ENV['RESET_TOKEN']
      render json: { error: "Invalid token" }, status: :unauthorized
    end
  end
end
