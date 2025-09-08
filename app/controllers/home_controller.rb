class HomeController < ApplicationController
  def index
    if user_signed_in?
      # ログインユーザーには公開投稿 + 自分の投稿 + 自分宛の投稿を表示
      public_posts = Post.where(is_private: false).includes(:user, images_attachments: :blob, videos_attachments: :blob, audios_attachments: :blob)
      own_posts = current_user.posts.where(is_private: true).includes(:user, images_attachments: :blob, videos_attachments: :blob, audios_attachments: :blob)
      received_posts = current_user.received_posts.where(is_private: true).includes(:user, images_attachments: :blob, videos_attachments: :blob, audios_attachments: :blob)
      
      # 後方互換性のため、古いメッセージベースでも受信投稿を取得
      message_based_post_ids = Message.joins(room: :entries)
                                     .where(entries: { user_id: current_user.id })
                                     .where.not(user_id: current_user.id)
                                     .where.not(post_id: nil)
                                     .pluck(:post_id)
                                     .uniq
      
      message_based_posts = Post.where(id: message_based_post_ids, is_private: true).includes(:user, images_attachments: :blob, videos_attachments: :blob, audios_attachments: :blob)
      
      all_post_ids = (public_posts.pluck(:id) + own_posts.pluck(:id) + received_posts.pluck(:id) + message_based_posts.pluck(:id)).uniq
      base_query = Post.where(id: all_post_ids)
      
      if params[:creation_type].present?
        filtered_posts = base_query.where(creation_type: params[:creation_type]).includes(:comments, :user, :votes, images_attachments: :blob, videos_attachments: :blob, audios_attachments: :blob)
      elsif params[:filter] == 'following'
        # フォロー中のユーザーの投稿のみを表示
        begin
          following_user_ids = current_user.following.pluck(:id)
          filtered_posts = base_query.where(user_id: following_user_ids).includes(:comments, :user, :votes, images_attachments: :blob, videos_attachments: :blob, audios_attachments: :blob)
        rescue ActiveRecord::StatementInvalid
          # フォロー機能がない場合は全投稿を表示
          filtered_posts = base_query.includes(:comments, :user, :votes, images_attachments: :blob, videos_attachments: :blob, audios_attachments: :blob)
        end
      else
        filtered_posts = base_query.includes(:comments, :user, :votes, images_attachments: :blob, videos_attachments: :blob, audios_attachments: :blob)
      end

      # レコメンドシステムを使用してソート（バズ回避設計）
      recommendation_service = RecommendationService.new(current_user)
      recommended_posts = recommendation_service.recommend_for_home_feed(filtered_posts, {
        max_posts: 50,
        diversity_factor: 0.8,
        avoid_viral_content: true,
        max_same_creator: 3,
        quality_over_popularity: true
      })
      
      # 推奨された投稿のIDを取得し、画像付きで再クエリ
      recommended_post_ids = recommended_posts.map(&:id)
      if recommended_post_ids.any?
        posts_with_preloads = Post.where(id: recommended_post_ids).includes(:user, :comments, :votes, images_attachments: :blob, videos_attachments: :blob, audios_attachments: :blob)
        # 推奨順序を保持
        @posts = recommended_post_ids.map { |id| posts_with_preloads.find { |p| p.id == id } }.compact
      else
        @posts = []
      end
    else
      # 未ログインユーザーには公開投稿のみ表示（時系列順）
      if params[:creation_type].present?
        @posts = Post.where(creation_type: params[:creation_type], is_private: false).includes(:comments, :user, images_attachments: :blob, videos_attachments: :blob, audios_attachments: :blob).order(created_at: :desc)
      else
        @posts = Post.where(is_private: false).includes(:comments, :user, images_attachments: :blob, videos_attachments: :blob, audios_attachments: :blob).order(created_at: :desc)
      end
    end
  end
end
