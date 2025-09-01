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
    @posts = @user.posts.where(is_private: false).order(created_at: :desc)
    @supporter_profile = @user.supporter_profile
  end


  def mypage
    @user = current_user
    
    # 自分の投稿と自分宛に送られた投稿を合わせて表示
    own_posts = current_user.posts
    received_posts = current_user.received_posts
    
    # 後方互換性のため、古いメッセージベースでも受信投稿を取得
    message_based_post_ids = Message.joins(room: :entries)
                                   .where(entries: { user_id: current_user.id })
                                   .where.not(user_id: current_user.id)
                                   .where.not(post_id: nil)
                                   .pluck(:post_id)
                                   .uniq
    
    message_based_posts = Post.where(id: message_based_post_ids, is_private: true)
    
    all_post_ids = (own_posts.pluck(:id) + received_posts.pluck(:id) + message_based_posts.pluck(:id)).uniq
    @posts = Post.where(id: all_post_ids)
                 .includes(:user, images_attachments: :blob)
                 .order(created_at: :desc)
    
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

  def update
    @user = current_user
    
    if @user.update(user_params)
      redirect_to mypage_path, notice: 'ユーザーネームが更新されました。'
    else
      redirect_to mypage_path, alert: @user.errors.full_messages.join(', ')
    end
  end

  private

  def user_params
    params.require(:user).permit(:name)
  end
end
