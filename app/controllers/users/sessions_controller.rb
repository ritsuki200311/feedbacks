# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  def create
    # ユーザー名からユーザーを検索
    user = User.find_by(name: params[:user][:name])

    if user
      # ユーザーが見つかった場合、そのユーザーでサインイン
      if user.valid_password?(user.name)
        sign_in(user)
        redirect_to root_path
      else
        # パスワードが一致しない場合、パスワードをユーザー名に更新
        user.update(password: user.name, password_confirmation: user.name)
        sign_in(user)
        redirect_to root_path
      end
    else
      # ユーザーが見つからない場合
      flash[:alert] = "ユーザー名が見つかりません。新規登録してください。"
      redirect_to new_user_session_path
    end
  end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
end
