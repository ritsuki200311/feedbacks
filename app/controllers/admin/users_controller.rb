module Admin
  class UsersController < ApplicationController
    before_action :authenticate_user!
    before_action :restrict_to_development!
    before_action :set_user, only: [ :add_coins, :remove_coins ]

    def index
      @users = User.includes(:preference).all
      @show_sensitive_info = Rails.env.development?
    end

    def add_coins
      amount = params[:amount].to_i
      if amount > 0
        @user.add_coins(amount)
        redirect_to admin_users_path, notice: "#{@user.name}のコインを#{amount}増やしました。"
      else
        redirect_to admin_users_path, alert: "コインの枚数は1以上で入力してください。"
      end
    end

    def remove_coins
      amount = params[:amount].to_i
      if amount > 0
        @user.remove_coins(amount)
        redirect_to admin_users_path, notice: "#{@user.name}のコインを#{amount}減らしました。"
      else
        redirect_to admin_users_path, alert: "コインの枚数は1以上で入力してください。"
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def restrict_to_development!
      return if Rails.env.development?
      redirect_to root_path, alert: "このページにはアクセスできません。"
    end
  end
end
