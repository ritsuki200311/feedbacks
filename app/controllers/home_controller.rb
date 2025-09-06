class HomeController < ApplicationController
  def index
    if user_signed_in?
      # ログインユーザーには公開投稿 + 自分の投稿 + 自分宛の投稿を表示
      public_posts = Post.where(is_private: false)
      own_posts = current_user.posts.where(is_private: true)
      received_posts = current_user.received_posts.where(is_private: true)
      
      # 後方互換性のため、古いメッセージベースでも受信投稿を取得
      message_based_post_ids = Message.joins(room: :entries)
                                     .where(entries: { user_id: current_user.id })
                                     .where.not(user_id: current_user.id)
                                     .where.not(post_id: nil)
                                     .pluck(:post_id)
                                     .uniq
      
      message_based_posts = Post.where(id: message_based_post_ids, is_private: true)
      
      all_post_ids = (public_posts.pluck(:id) + own_posts.pluck(:id) + received_posts.pluck(:id) + message_based_posts.pluck(:id)).uniq
      base_query = Post.where(id: all_post_ids)
      
      if params[:creation_type].present?
        @posts = base_query.where(creation_type: params[:creation_type]).includes(:comments).order(created_at: :desc)
      elsif params[:filter] == 'following'
        # フォロー中のユーザーの投稿のみを表示
        following_user_ids = current_user.following.pluck(:id)
        @posts = base_query.where(user_id: following_user_ids).includes(:comments).order(created_at: :desc)
      else
        @posts = base_query.includes(:comments).order(created_at: :desc)
      end
    else
      # 未ログインユーザーには公開投稿のみ表示
      if params[:creation_type].present?
        @posts = Post.where(creation_type: params[:creation_type], is_private: false).includes(:comments).order(created_at: :desc)
      else
        @posts = Post.where(is_private: false).includes(:comments).order(created_at: :desc)
      end
    end
  end
end
