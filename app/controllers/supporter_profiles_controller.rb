class SupporterProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_supporter_profile, only: [:edit, :update]
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

  def show
    @supporter_profile = current_user.supporter_profile
    unless @supporter_profile
      redirect_to new_supporter_profile_path, alert: "プロフィールがまだ登録されていません。" and return
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
    ).tap do |whitelisted|
      whitelisted[:standing] = whitelisted[:standing].join(',') if whitelisted[:standing].is_a?(Array)
      whitelisted[:interests] = whitelisted[:interests].join(',') if whitelisted[:interests].is_a?(Array)
      whitelisted[:support_genres] = whitelisted[:support_genres].join(',') if whitelisted[:support_genres].is_a?(Array)
      whitelisted[:support_styles] = whitelisted[:support_styles].join(',') if whitelisted[:support_styles].is_a?(Array)
      whitelisted[:personality_traits] = whitelisted[:personality_traits].join(',') if whitelisted[:personality_traits].is_a?(Array)
    end
  end

end
