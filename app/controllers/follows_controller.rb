class FollowsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def create
    if current_user == @user
      redirect_back_or_to(user_path(@user), alert: "自分自身をフォローすることはできません")
      return
    end

    if current_user.following?(@user)
      redirect_back_or_to(user_path(@user), alert: "既にフォローしています")
      return
    end

    @follow = current_user.active_follows.build(followed: @user)
    
    if @follow.save
      redirect_back_or_to(user_path(@user), notice: "#{@user.name}をフォローしました")
    else
      redirect_back_or_to(user_path(@user), alert: "フォローできませんでした")
    end
  end

  def destroy
    @follow = current_user.active_follows.find_by(followed: @user)
    
    if @follow
      @follow.destroy
      redirect_back_or_to(user_path(@user), notice: "#{@user.name}のフォローを解除しました")
    else
      redirect_back_or_to(user_path(@user), alert: "フォローしていません")
    end
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "ユーザーが見つかりません"
  end

  def redirect_back_or_to(default, **options)
    redirect_to(request.referer || default, **options)
  end
end