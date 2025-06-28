class PostsController < ApplicationController
  before_action :set_post, only: [:show, :edit, :update, :destroy]

  def new
    @post = Post.new
  end

  def create
    @post = Post.new(post_params.except(:tag_list)) # 仮想属性を除く
    @post.user = current_user
    @post.tag_list = post_params[:tag_list]         # 手動で代入
    @post.filter_list = post_params[:filter_list]   # 仮想属性（将来用途）
    @post.recipient_standing = post_params[:recipient_standing] # 送信対象の条件
    @post.recipient_support_styles = post_params[:recipient_support_styles]
    @post.recipient_age_group = post_params[:recipient_age_group]
  
    cost = Rails.application.config.x.coin.post_cost
    if current_user.coins < cost
      redirect_to new_post_path, alert: "コインが不足しています。" and return
    end
  
    if @post.save
      current_user.decrement!(:coins, cost)  # コインを減らす
  
      # ★ここから：条件にマッチする支援者へ動画を送信
      matched_supporters = SupporterProfile.includes(:user).select do |profile|
        standing_match = @post.recipient_standing.blank? || (@post.recipient_standing & profile.standing_array).any?
        support_style_match = @post.recipient_support_styles.blank? || (@post.recipient_support_styles & profile.support_styles_array).any?
        age_group_match = @post.recipient_age_group.blank? || @post.recipient_age_group.include?(profile.age_group)
  
        standing_match && support_style_match && age_group_match
      end
  
      matched_supporters.each do |profile|
        ReceivedVideo.create!(
          user: profile.user,             # 受信者
          sender: current_user,           # 送信者
          post: @post,
          title: @post.title,
          thumbnail_url: @post.thumbnail_url # 必要に応じて設定
        )
      end
      # ★ここまで
  
      redirect_to posts_path, notice: '投稿が作成されました。'
    else
      render :new
    end
  end
  

  def show
    @comment = @post.comments.build  # コメント投稿フォーム用
  end

  def edit
    # @post は before_action でセット済み
  end

  def update
    if @post.update(post_params)
      redirect_to @post, notice: "投稿が更新されました。"
    else
      render :edit
    end
  end

  def destroy
    @post.destroy
    redirect_to root_path, notice: "投稿が削除されました。"
  end

  private

  def post_params
    params.require(:post).permit(:title, :content, tag_list: [],
      recipient_standing: [], recipient_support_styles: [], recipient_age_group: [])
  end
  
  def set_post
    @post = Post.find(params[:id])
  end
end