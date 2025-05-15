# app/controllers/preferences_controller.rb
class PreferencesController < ApplicationController
  before_action :authenticate_user!

  def new
    # すでに好みがある場合は編集フォームへリダイレクト（任意）
    if current_user.preference
      redirect_to edit_preference_path(current_user.preference)
    else
      @preference = Preference.new
    end
  end

  def create
    @preference = current_user.build_preference(preference_params)
  
    if @preference.save
      redirect_to root_path, notice: "好みを登録しました"
    else
      puts @preference.errors.full_messages  # これ追加！
      flash.now[:alert] = "登録に失敗しました"
      render :new
    end
  end  

  def edit
    @preference = current_user.preference
  end

  def update
    @preference = current_user.preference

    if @preference.update(preference_params)
      redirect_to mypage_path, notice: "好みを更新しました"
    else
      flash.now[:alert] = "更新に失敗しました"
      render :edit
    end
  end

  private

  def preference_params
    params.require(:preference).permit(:genre, :instrument_experience, :favorite_artist, :career)
  end
end
