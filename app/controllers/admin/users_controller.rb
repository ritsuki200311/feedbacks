module Admin
  class UsersController < ApplicationController
    def index
      # 開発環境でのみ全ての情報を表示
      if Rails.env.development?
        @users = User.includes(:preference).all
        @show_sensitive_info = true
      else
        @users = User.includes(:preference).all
        @show_sensitive_info = false
      end
    end
  end
end