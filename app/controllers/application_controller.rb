class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :configure_permitted_parameters, if: :devise_controller?


  # ログアウト後のリダイレクト先をログインページに設定
  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path # Deviseのログインページ
  end

  protected

  # # サインアップ後のリダイレクト先を設定
  # def after_sign_up_path_for(resource)
  #   new_preference_path
  # end
  
  # def after_inactive_sign_up_path_for(resource)
  #   new_preference_path
  # end

  

  def configure_permitted_parameters
    # ユーザー登録時に name フィールドを許可
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    # ユーザー情報更新時に name フィールドを許可
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end
end