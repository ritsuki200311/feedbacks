class UsersController < ApplicationController
  def index
    render plain: "Hello, world!"
  end
  def mypage
    @user = current_user
    @posts = current_user.posts.order(created_at: :desc) # 自分の投稿を新しい順に取得

    # @posts = @user.posts
    # render :mypage
  end

  def show
    @user = User.find(params[:id])
    @posts = @user.posts.order(created_at: :desc) # ユーザーの投稿を新しい順に取得

    # 自分のプロフィールページにアクセスしようとしたらマイページへ
    if @user == current_user
      redirect_to mypage_path and return
    end
  end

  def mypage
    @user = current_user
    @posts = current_user.posts.order(created_at: :desc)
  
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