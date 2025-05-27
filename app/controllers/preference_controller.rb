# app/controllers/preferences_controller.rb
class PreferencesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_preference, only: [:edit, :update]

  def new
    # すでに好みがある場合は編集フォームへリダイレクト
    if current_user.preference
      redirect_to edit_preference_path
    else
      @preference = Preference.new
    end
  end

  def create
    @preference = current_user.build_preference(preference_params)
    if @preference.save
      redirect_to root_path, notice: "好みを登録しました"
    else
      flash.now[:alert] = "登録に失敗しました"
      render :new
    end
  end

  def edit
  end

  def update
    if @preference.update(preference_params)
      redirect_to root_path, notice: "好みを更新しました"
    else
      flash.now[:alert] = "更新に失敗しました"
      render :edit
    end
  end

  private

  def preference_params
    params.require(:preference).permit(:genre, :instrument_experience, :favorite_artist, :career, :selected_items)
  end

  def set_preference
    @preference = current_user.preference
    unless @preference
      redirect_to new_preference_path, alert: "好みの設定が必要です"
    end
  end
end