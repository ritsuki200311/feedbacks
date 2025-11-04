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
      elsif params[:filter] == "following"
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

      # 「最新」タブが選択された場合は時系列順、それ以外はレコメンド順
      if params[:sort] == "latest"
        @posts = filtered_posts.order(created_at: :desc)
      else
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
          all_posts = recommended_post_ids.map { |id| posts_with_preloads.find { |p| p.id == id } }.compact

          # 自分の投稿を上位に移動（新しい順）
          own_posts = all_posts.select { |post| post.user_id == current_user.id }.sort_by(&:created_at).reverse
          other_posts = all_posts.reject { |post| post.user_id == current_user.id }
          @posts = own_posts + other_posts
        else
          @posts = []
        end
      end
    else
      # 未ログインユーザーには公開投稿のみ表示
      if params[:creation_type].present?
        posts = Post.where(creation_type: params[:creation_type], is_private: false).includes(:comments, :user, images_attachments: :blob, videos_attachments: :blob, audios_attachments: :blob)
      else
        posts = Post.where(is_private: false).includes(:comments, :user, images_attachments: :blob, videos_attachments: :blob, audios_attachments: :blob)
      end

      # 「最新」タブが選択された場合は時系列順
      if params[:sort] == "latest"
        @posts = posts.order(created_at: :desc)
      else
        @posts = posts.order(created_at: :desc)  # 未ログインユーザーは常に時系列順
      end
    end

    # 右サイドバー用のデータを取得
    # 最近の高評価コメントを取得
    begin
      # 過去7日間のコメントを取得し、Rubyでスコア計算
      recent_comments = Comment.where("created_at >= ?", 7.days.ago)
                              .includes(:user, :post, :votes)
                              .order(created_at: :desc)

      # スコアを計算してソート
      @recent_comments = recent_comments.select { |comment|
        comment.votes.sum(:value) > 0  # プラススコアのもののみ
      }.sort_by { |comment|
        -comment.votes.sum(:value)  # スコアの降順
      }.first(5)

    rescue => e
      Rails.logger.error "高評価コメント取得エラー: #{e.message}"
      # フォールバック: 最近のコメントを表示
      @recent_comments = Comment.includes(:user, :post)
                               .order(created_at: :desc)
                               .limit(5)
    end

    # 新しいコメントも取得（高評価コメントと重複しないように）
    # 高評価コメントのIDを除外
    highly_rated_ids = @recent_comments.is_a?(Array) ? @recent_comments.map(&:id) : @recent_comments.pluck(:id)
    @new_comments = Comment.where.not(id: highly_rated_ids)
                          .includes(:user, :post)
                          .order(created_at: :desc)
                          .limit(5)

    # おすすめユーザーを取得（投稿数順）
    user_post_counts = Post.group(:user_id).count
    recommended_user_ids = user_post_counts.sort_by { |user_id, count| -count }.first(5).map(&:first)

    if current_user
      recommended_user_ids = recommended_user_ids.reject { |id| id == current_user.id }
    end

    @recommended_users = User.where(id: recommended_user_ids)
                            .includes(:posts)
                            .index_by(&:id)
                            .values_at(*recommended_user_ids)
                            .compact

    # 投稿の間に挿入するためのコメントリストを作成
    @insertable_comments = (@recent_comments + @new_comments).uniq.shuffle
  end
end
