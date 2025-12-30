# app/controllers/users/confirmations_controller.rb
class Users::ConfirmationsController < Devise::ConfirmationsController
  # GET /users/confirmation?confirmation_token=abcdef
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    yield resource if block_given?

    if resource.errors.empty?
      set_flash_message!(:notice, :confirmed)

      # メール確認後に自動ログイン
      sign_in(resource_name, resource)

      respond_with_navigational(resource) do
        redirect_to after_confirmation_path_for(resource_name, resource)
      end
    else
      respond_with_navigational(resource.errors, status: :unprocessable_entity) do
        render :new
      end
    end
  end

  protected

  # 確認後のリダイレクト先をプロフィール入力画面に設定
  def after_confirmation_path_for(resource_name, resource)
    # すでにSupporterProfileが存在する場合は編集画面、なければ新規作成画面
    if resource.supporter_profile
      edit_supporter_profile_path(resource.supporter_profile)
    else
      new_supporter_profile_path
    end
  end
end
