class UsersController < ApplicationController
  def index
    @users = User.includes(:preference).all
  end

  def show
    @user = User.find(params[:id])
    if user_signed_in? && @user == current_user
      redirect_to mypage_path
      return
    end
    @posts = @user.posts.order(created_at: :desc)
    @supporter_profile = @user.supporter_profile
  end


  def mypage
    @user = current_user
    @posts = current_user.posts.order(created_at: :desc)
    @supporter_profile = @user.supporter_profile

    # 自分が参加しているルームの中で未読メッセージがあるもの
    @unread_rooms = Room.joins(:messages, :entries)
                        .where(entries: { user_id: @user.id })
                        .where.not(messages: { user_id: @user.id }) # 自分が送ったのは除外
                        .where(messages: { is_read: false })
                        .distinct

    # 各ルームごとの未読件数
    @unread_counts = Message.where(room: @unread_rooms, is_read: false)
                            .where.not(user_id: @user.id)
                            .group(:room_id)
                            .count
  end
end
