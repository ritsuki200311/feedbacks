# app/controllers/users/registrations_controller.rb
class Users::RegistrationsController < Devise::RegistrationsController
    before_action :configure_permitted_parameters, if: :devise_controller?
    before_action :destroy_unconfirmed_users, only: [:create]

    protected

    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
      devise_parameter_sanitizer.permit(:account_update, keys: [:name, :bio])
    end

    def after_sign_up_path_for(resource)
      new_preference_path
    end

    private

    def destroy_unconfirmed_users
      # 同じメールアドレスまたはユーザー名で未確認のユーザーがいる場合は削除
      email = params.dig(:user, :email)
      name = params.dig(:user, :name)

      if email.present?
        unconfirmed_by_email = User.where(email: email).where("confirmed_at IS NULL")
        unconfirmed_by_email.destroy_all if unconfirmed_by_email.any?
      end

      if name.present?
        unconfirmed_by_name = User.where(name: name).where("confirmed_at IS NULL")
        unconfirmed_by_name.destroy_all if unconfirmed_by_name.any?
      end
    end
end
