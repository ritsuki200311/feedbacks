module Admin
  class UsersController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_admin_access!
    before_action :restrict_to_development!
    before_action :set_user, only: [ :add_coins, :remove_coins ]

    def index
      @users = User.includes(:preference).all
      @show_sensitive_info = Rails.env.development?
    end

    def add_coins
      amount = params[:amount].to_i
      if amount > 0 && amount <= 10000 # 1回の操作上限
        if @user.add_coins(amount)
          redirect_to admin_users_path, notice: "#{@user.name}のコインを#{amount}増やしました。"
        else
          redirect_to admin_users_path, alert: "コインの追加に失敗しました。上限を超えています。"
        end
      else
        redirect_to admin_users_path, alert: "コインの枚数は1〜10000で入力してください。"
      end
    end

    def remove_coins
      amount = params[:amount].to_i
      if amount > 0 && amount <= 10000 # 1回の操作上限
        if @user.remove_coins(amount)
          redirect_to admin_users_path, notice: "#{@user.name}のコインを#{amount}減らしました。"
        else
          redirect_to admin_users_path, alert: "コインの削除に失敗しました。残高が不足しています。"
        end
      else
        redirect_to admin_users_path, alert: "コインの枚数は1〜10000で入力してください。"
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def ensure_admin_access!
      # 実際の運用では、管理者フラグやロールベースの認証を実装
      # 現在は開発環境での動作確認のため、全ログインユーザーを許可
      redirect_to root_path, alert: "管理者権限が必要です。" unless current_user&.id
    end

    def restrict_to_development!
      return if Rails.env.development?
      redirect_to root_path, alert: "このページにはアクセスできません。"
    end
  end
end
