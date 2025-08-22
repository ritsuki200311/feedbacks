class SupporterProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_supporter_profile, only: [ :edit, :update ]
  before_action :authenticate_user!

  def new
    if current_user.supporter_profile
      redirect_to edit_supporter_profile_path(current_user.supporter_profile)
    else
      @supporter_profile = SupporterProfile.new
    end
  end

  def create
    @supporter_profile = current_user.build_supporter_profile(supporter_profile_params)

    if @supporter_profile.save
      redirect_to mypage_path, notice: "プロフィールを作成しました。"
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @supporter_profile.update(supporter_profile_params)
      redirect_to mypage_path, notice: "プロフィールを更新しました。"
    else
      render :edit
    end
  end


  private

  def set_supporter_profile
    @supporter_profile = current_user.supporter_profile
  end

  def supporter_profile_params
    params.require(:supporter_profile).permit(
      :creation_experience, :favorite_artists, :age_group,
      standing: [], interests: [], support_genres: [], support_styles: [], personality_traits: []
    )
  end
end
