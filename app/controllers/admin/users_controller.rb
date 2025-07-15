module Admin
  class UsersController < ApplicationController
    def index
      @users = User.includes(:preference).all
    end
  end
end
