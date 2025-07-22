module Admin
  class UsersController < ApplicationController
    before_action :set_user, only: [:add_coins, :remove_coins]

    def index
      @users = User.includes(:preference).all
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
  end
end
