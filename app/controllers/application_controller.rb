class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :configure_permitted_parameters, if: :devise_controller?


  # ログアウト後のリダイレクト先をログインページに設定
  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path # Deviseのログインページ
  end

  # 初回ログイン時はプロフィール登録へ誘導
  def after_sign_in_path_for(resource)
    if resource.is_a?(User) && resource.supporter_profile.blank?
      new_supporter_profile_path
    else
      stored_location_for(resource) || root_path
    end
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
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
    # ユーザー情報更新時に name フィールドを許可
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end

  private

  # デバイスを検出してレイアウトを設定
  def set_device_layout
    if mobile_device?
      self.class.layout "MobileLayout/application"
    else
      self.class.layout "DesktopLayout/application"
    end
  end

  # モバイルデバイスかどうかを判定
  def mobile_device?
    user_agent = request.user_agent.to_s.downcase
    # JavaScriptのisMobileDevice関数をRubyに変換
    user_agent =~ /iphone|android(?!.*mobile)|ipod|ipad/
  end

  # ヘルパーメソッドとして使用できるようにする
  helper_method :mobile_device?
end
