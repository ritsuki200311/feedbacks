class CommunitiesController < ApplicationController
  helper :posts
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_community, only: [:show, :edit, :update, :destroy, :join, :leave]

  def index
    @communities = Community.where(is_public: true)
  end

  def show
    @posts = @community.posts.order(created_at: :desc)
  end

  def new
    @community = Community.new
  end

  def create
    @community = Community.new(community_params)
    @community.user_id = current_user.id # 作成者を設定
    if @community.save
      # コミュニティを作成したユーザーを自動的に参加させる
      @community.users << current_user
      redirect_to @community, notice: "コミュニティを作成しました。"
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @community.update(community_params)
      redirect_to @community, notice: "コミュニティ情報を更新しました。"
    else
      render :edit
    end
  end

  def destroy
    @community.destroy
    redirect_to communities_url, notice: "コミュニティを削除しました。"
  end

  def join
    @community.users << current_user
    redirect_to @community, notice: "コミュニティに参加しました。"
  end

  def leave
    @community.users.delete(current_user)
    redirect_to @community, notice: "コミュニティから脱退しました。"
  end

  private

  def set_community
    @community = Community.find(params[:id])
  end

  def community_params
    params.require(:community).permit(:name, :description, :is_public, :tags)
  end
end
